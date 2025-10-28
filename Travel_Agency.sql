DROP TABLE IF EXISTS booking_excursions CASCADE;
DROP TABLE IF EXISTS travelers CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS excursions CASCADE;
DROP TABLE IF EXISTS tour_destinations CASCADE;
DROP TABLE IF EXISTS tours CASCADE;
DROP TABLE IF EXISTS destinations CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS clients CASCADE;



-- Table: clients
-- Stores information about customers of the travel agency
CREATE TABLE clients
(
    client_id         SERIAL PRIMARY KEY,
    first_name        VARCHAR(100)        NOT NULL,
    last_name         VARCHAR(100)        NOT NULL,
    email             VARCHAR(150) UNIQUE NOT NULL,
    phone             VARCHAR(20)         NOT NULL,
    address           TEXT,
    registration_date DATE                NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Table: employees
-- Stores agency employees with hierarchical relationship (manager-employee)
-- RECURSIVE RELATIONSHIP: manager_id → employee_id
CREATE TABLE employees
(
    employee_id SERIAL PRIMARY KEY,
    first_name  VARCHAR(100)        NOT NULL,
    last_name   VARCHAR(100)        NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    phone       VARCHAR(20)         NOT NULL,
    position    VARCHAR(100)        NOT NULL,
    hire_date   DATE                NOT NULL,
    salary      NUMERIC(10, 2) CHECK (salary > 0),
    manager_id  INTEGER,
    CONSTRAINT fk_manager FOREIGN KEY (manager_id)
        REFERENCES employees (employee_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_not_self_manager CHECK (employee_id != manager_id)
);

-- Table: destinations
-- Stores cities/countries that can be included in tours
CREATE TABLE destinations
(
    destination_id SERIAL PRIMARY KEY,
    country        VARCHAR(100) NOT NULL,
    city           VARCHAR(100) NOT NULL,
    description    TEXT,
    hotel_name     VARCHAR(200),
    hotel_rating   INTEGER CHECK (hotel_rating BETWEEN 1 AND 5),
    best_season    VARCHAR(50),
    CONSTRAINT uq_country_city UNIQUE (country, city)
);

-- Table: tours
-- Stores tour packages offered by the agency
CREATE TABLE tours
(
    tour_id          SERIAL PRIMARY KEY,
    tour_name        VARCHAR(200)   NOT NULL,
    description      TEXT,
    duration_days    INTEGER        NOT NULL CHECK (duration_days > 0),
    price_per_person NUMERIC(10, 2) NOT NULL CHECK (price_per_person > 0),
    max_group_size   INTEGER CHECK (max_group_size > 0),
    difficulty_level VARCHAR(20) CHECK (difficulty_level IN ('Easy', 'Moderate', 'Difficult')),
    is_active        BOOLEAN        NOT NULL DEFAULT TRUE
);

-- Table: tour_destinations (M:N relationship #1)
-- Links tours with their destinations (a tour can include multiple destinations)
CREATE TABLE tour_destinations
(
    tour_id        INTEGER NOT NULL,
    destination_id INTEGER NOT NULL,
    day_number     INTEGER NOT NULL CHECK (day_number > 0),
    notes          TEXT,
    PRIMARY KEY (tour_id, destination_id),
    CONSTRAINT fk_tour FOREIGN KEY (tour_id)
        REFERENCES tours (tour_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_destination FOREIGN KEY (destination_id)
        REFERENCES destinations (destination_id)
        ON DELETE CASCADE
);

-- Table: excursions
-- Stores optional excursions available at destinations
CREATE TABLE excursions
(
    excursion_id     SERIAL PRIMARY KEY,
    excursion_name   VARCHAR(200)   NOT NULL,
    description      TEXT,
    destination_id   INTEGER        NOT NULL,
    duration_hours   NUMERIC(4, 2)  NOT NULL CHECK (duration_hours > 0),
    price            NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    max_participants INTEGER CHECK (max_participants > 0),
    guide_name       VARCHAR(150),
    CONSTRAINT fk_excursion_destination FOREIGN KEY (destination_id)
        REFERENCES destinations (destination_id)
        ON DELETE CASCADE
);

-- Table: bookings
-- Stores customer bookings for tours
CREATE TABLE bookings
(
    booking_id          SERIAL PRIMARY KEY,
    client_id           INTEGER        NOT NULL,
    tour_id             INTEGER        NOT NULL,
    employee_id         INTEGER,
    booking_date        DATE           NOT NULL DEFAULT CURRENT_DATE,
    tour_start_date     DATE           NOT NULL,
    number_of_travelers INTEGER        NOT NULL CHECK (number_of_travelers > 0),
    total_price         NUMERIC(12, 2) NOT NULL CHECK (total_price >= 0),
    status              VARCHAR(20)    NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Confirmed', 'Cancelled', 'Completed')),
    payment_amount      NUMERIC(12, 2)          DEFAULT 0 CHECK (payment_amount >= 0),
    payment_date        DATE,
    payment_method      VARCHAR(50) CHECK (payment_method IN
                                           ('Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'PayPal')),
    special_requests    TEXT,
    CONSTRAINT fk_booking_client FOREIGN KEY (client_id)
        REFERENCES clients (client_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_booking_tour FOREIGN KEY (tour_id)
        REFERENCES tours (tour_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_booking_employee FOREIGN KEY (employee_id)
        REFERENCES employees (employee_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_tour_start CHECK (tour_start_date >= booking_date)
);

-- Table: travelers
-- Stores information about individual travelers in a booking
CREATE TABLE travelers
(
    traveler_id          SERIAL PRIMARY KEY,
    booking_id           INTEGER      NOT NULL,
    first_name           VARCHAR(100) NOT NULL,
    last_name            VARCHAR(100) NOT NULL,
    date_of_birth        DATE         NOT NULL,
    passport_number      VARCHAR(50)  NOT NULL,
    passport_expiry_date DATE         NOT NULL,
    nationality          VARCHAR(100) NOT NULL,
    CONSTRAINT fk_traveler_booking FOREIGN KEY (booking_id)
        REFERENCES bookings (booking_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_passport_expiry CHECK (passport_expiry_date > CURRENT_DATE),
    CONSTRAINT chk_age CHECK (date_of_birth < CURRENT_DATE)
);

-- Table: booking_excursions (M:N relationship #2)
-- Links bookings with selected optional excursions
CREATE TABLE booking_excursions
(
    booking_id             INTEGER        NOT NULL,
    excursion_id           INTEGER        NOT NULL,
    number_of_participants INTEGER        NOT NULL CHECK (number_of_participants > 0),
    scheduled_date         DATE           NOT NULL,
    total_price            NUMERIC(10, 2) NOT NULL CHECK (total_price >= 0),
    PRIMARY KEY (booking_id, excursion_id),
    CONSTRAINT fk_booking_excursion_booking FOREIGN KEY (booking_id)
        REFERENCES bookings (booking_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_booking_excursion_excursion FOREIGN KEY (excursion_id)
        REFERENCES excursions (excursion_id)
        ON DELETE CASCADE
);



CREATE INDEX idx_clients_email ON clients (email);
CREATE INDEX idx_bookings_client ON bookings (client_id);
CREATE INDEX idx_bookings_tour ON bookings (tour_id);
CREATE INDEX idx_bookings_status ON bookings (status);
CREATE INDEX idx_travelers_booking ON travelers (booking_id);
CREATE INDEX idx_tour_destinations_tour ON tour_destinations (tour_id);
CREATE INDEX idx_excursions_destination ON excursions (destination_id);
CREATE INDEX idx_employees_manager ON employees (manager_id);


COMMENT ON TABLE clients IS 'Stores customer information';
COMMENT ON TABLE employees IS 'Stores agency employees with manager hierarchy';
COMMENT ON TABLE destinations IS 'Cities and countries with basic hotel info';
COMMENT ON TABLE tours IS 'Tour packages offered by the agency';
COMMENT ON TABLE tour_destinations IS 'M:N relationship: tours and their destinations';
COMMENT ON TABLE excursions IS 'Optional excursions at destinations';
COMMENT ON TABLE bookings IS 'Customer bookings with payment info';
COMMENT ON TABLE travelers IS 'Individual travelers in each booking';
COMMENT ON TABLE booking_excursions IS 'M:N relationship: bookings and selected excursions';

COMMENT ON COLUMN employees.manager_id IS 'Reference to manager';
COMMENT ON COLUMN bookings.status IS 'Booking status: Pending, Confirmed, Cancelled, Completed';



INSERT INTO clients (first_name, last_name, email, phone, address, registration_date)
VALUES ('John', 'Smith', 'john.smith@email.com', '+1-555-0101', '123 Main St, New York, NY', '2024-01-15'),
       ('Emma', 'Johnson', 'emma.j@email.com', '+1-555-0102', '456 Oak Ave, Los Angeles, CA', '2024-02-20'),
       ('Michael', 'Brown', 'michael.brown@email.com', '+1-555-0103', '789 Pine Rd, Chicago, IL', '2024-03-10'),
       ('Sophia', 'Garcia', 'sophia.garcia@email.com', '+1-555-0104', '321 Elm St, Miami, FL', '2024-04-05'),
       ('James', 'Wilson', 'james.wilson@email.com', '+1-555-0105', '654 Maple Dr, Seattle, WA', '2024-05-12');


-- Сначала CEO без manager_id, затем остальные с manager_id
INSERT INTO employees (first_name, last_name, email, phone, position, hire_date, salary, manager_id)
VALUES ('Robert', 'Anderson', 'robert.anderson@agency.com', '+1-555-1001', 'CEO', '2020-01-01', 120000.00, NULL),
       ('Linda', 'Martinez', 'linda.martinez@agency.com', '+1-555-1002', 'Sales Manager', '2021-03-15', 85000.00, 1),
       ('David', 'Taylor', 'david.taylor@agency.com', '+1-555-1003', 'Operations Manager', '2021-06-01', 80000.00, 1),
       ('Sarah', 'Thomas', 'sarah.thomas@agency.com', '+1-555-1004', 'Travel Consultant', '2022-01-10', 55000.00, 2),
       ('Jennifer', 'Moore', 'jennifer.moore@agency.com', '+1-555-1005', 'Travel Consultant', '2022-04-20', 55000.00,
        2),
       ('Daniel', 'Jackson', 'daniel.jackson@agency.com', '+1-555-1006', 'Customer Support', '2022-08-15', 45000.00, 3),
       ('Emily', 'White', 'emily.white@agency.com', '+1-555-1007', 'Tour Coordinator', '2023-02-01', 50000.00, 3);


INSERT INTO destinations (country, city, description, hotel_name, hotel_rating, best_season)
VALUES ('France', 'Paris', 'The city of light, famous for Eiffel Tower and Louvre', 'Grand Hotel Paris', 5,
        'Spring-Fall'),
       ('Italy', 'Rome', 'Ancient city with Colosseum and Vatican', 'Rome Luxury Inn', 4, 'Spring-Fall'),
       ('Italy', 'Venice', 'Romantic city of canals and gondolas', 'Venice Palace Hotel', 5, 'Spring-Summer'),
       ('Spain', 'Barcelona', 'Vibrant city with Gaudi architecture', 'Barcelona Beach Resort', 4, 'Spring-Fall'),
       ('Thailand', 'Bangkok', 'Bustling capital with temples and street food', 'Bangkok Grand Hotel', 5, 'Nov-Feb'),
       ('Thailand', 'Phuket', 'Beautiful beaches and island paradise', 'Phuket Paradise Resort', 5, 'Nov-Apr'),
       ('Mexico', 'Cancun', 'Beach resort with Mayan ruins nearby', 'Cancun Beach Hotel', 4, 'Dec-Apr'),
       ('USA', 'New York', 'The Big Apple, business and cultural hub', 'NYC Manhattan Hotel', 4, 'Spring-Fall');


INSERT INTO tours (tour_name, description, duration_days, price_per_person, max_group_size, difficulty_level, is_active)
VALUES ('European Grand Tour', 'Visit Paris, Rome, Venice and Barcelona in one amazing journey', 12, 2499.99, 20,
        'Easy', TRUE),
       ('Italian Highlights', 'Explore Rome and Venice, the jewels of Italy', 7, 1599.99, 15, 'Easy', TRUE),
       ('Thailand Adventure', 'Experience Bangkok city life and Phuket beaches', 10, 1899.99, 18, 'Moderate', TRUE),
       ('Paris Romance Getaway', 'Perfect romantic trip to the city of love', 5, 1299.99, 10, 'Easy', TRUE),
       ('Mediterranean Explorer', 'Discover Rome and Barcelona culture', 8, 1799.99, 16, 'Moderate', TRUE);


INSERT INTO tour_destinations (tour_id, destination_id, day_number, notes)
VALUES
-- European Grand Tour: Paris → Rome → Venice → Barcelona
(1, 1, 1, 'Days 1-3: Explore Paris'),
(1, 2, 4, 'Days 4-6: Ancient Rome'),
(1, 3, 7, 'Days 7-9: Venice canals'),
(1, 4, 10, 'Days 10-12: Barcelona beaches'),
-- Italian Highlights: Rome → Venice
(2, 2, 1, 'Days 1-4: Rome exploration'),
(2, 3, 5, 'Days 5-7: Venice romance'),
-- Thailand Adventure: Bangkok → Phuket
(3, 5, 1, 'Days 1-5: Bangkok city'),
(3, 6, 6, 'Days 6-10: Phuket beaches'),
-- Paris Romance: только Paris
(4, 1, 1, 'All 5 days in Paris'),
-- Mediterranean Explorer: Rome → Barcelona
(5, 2, 1, 'Days 1-4: Rome'),
(5, 4, 5, 'Days 5-8: Barcelona');


INSERT INTO excursions (excursion_name, description, destination_id, duration_hours, price, max_participants,
                        guide_name)
VALUES
-- Paris
('Eiffel Tower & Seine Cruise', 'Visit Eiffel Tower with romantic river cruise', 1, 4.0, 89.99, 30, 'Pierre Leroy'),
('Louvre Museum Tour', 'Guided tour of world famous Louvre', 1, 3.5, 75.00, 25, 'Pierre Leroy'),
('Versailles Palace Day Trip', 'Full day at magnificent Versailles', 1, 8.0, 149.99, 20, 'Marie Dubois'),
-- Rome
('Colosseum & Roman Forum', 'Ancient Rome walking tour', 2, 3.0, 65.00, 30, 'Giovanni Ferrari'),
('Vatican Museums & Sistine Chapel', 'Art and history at Vatican', 2, 4.0, 85.00, 20, 'Giovanni Ferrari'),
-- Barcelona
('Sagrada Familia & Park Güell', 'Gaudi architectural masterpieces', 4, 4.5, 79.99, 25, 'Maria Gonzalez'),
('Gothic Quarter Walking Tour', 'Medieval Barcelona exploration', 4, 2.5, 45.00, 30, 'Carlos Martinez'),
-- Bangkok
('Grand Palace & Wat Pho', 'Bangkok temples and palace tour', 5, 4.0, 55.00, 30, 'Niran Suwan'),
('Floating Market Experience', 'Traditional Thai market boat tour', 5, 5.0, 65.00, 20, 'Lek Pongsakul'),
-- Phuket
('Phi Phi Islands Day Trip', 'Island hopping and snorkeling', 6, 8.0, 120.00, 35, 'Somchai Wong'),
('James Bond Island Tour', 'Phang Nga Bay scenic tour', 6, 6.0, 95.00, 30, 'Somchai Wong'),
-- Cancun
('Chichen Itza Mayan Ruins', 'Ancient pyramid and cenote swim', 7, 10.0, 135.00, 40, 'Carlos Hernandez');


INSERT INTO bookings (client_id, tour_id, employee_id, booking_date, tour_start_date, number_of_travelers, total_price,
                      status, payment_amount, payment_date, payment_method, special_requests)
VALUES
-- Подтвержденные бронирования
(1, 1, 4, '2025-03-15', '2025-06-01', 2, 5249.98, 'Confirmed', 5249.98, '2025-05-01', 'Credit Card',
 'Need room with city view'),
(2, 4, 4, '2025-04-20', '2025-07-10', 2, 2899.98, 'Confirmed', 2899.98, '2025-04-20', 'Credit Card',
 'Anniversary trip, romantic setup please'),
(3, 3, 5, '2025-05-01', '2025-08-15', 3, 6049.97, 'Confirmed', 3024.99, '2025-05-01', 'Bank Transfer',
 'Traveling with 10 year old child'),
-- В ожидании
(4, 2, 5, '2025-10-25', '2025-12-01', 2, 3549.98, 'Pending', 1774.99, '2025-10-25', 'PayPal', NULL),
(5, 5, 4, '2025-10-26', '2025-11-20', 4, 7649.96, 'Pending', 3824.98, '2025-10-26', 'Credit Card',
 'Vegetarian meals required'),
-- Завершенные
(1, 4, 4, '2024-06-01', '2024-08-15', 2, 2849.98, 'Completed', 2849.98, '2024-06-01', 'Credit Card', NULL),
(3, 2, 5, '2024-08-10', '2024-10-05', 2, 3449.98, 'Completed', 3449.98, '2024-08-10', 'Debit Card', NULL),
-- Отмененные
(2, 3, 4, '2025-09-01', '2025-11-01', 2, 4149.98, 'Cancelled', 2074.99, '2025-09-01', 'Credit Card',
 'Cancelled due to change of plans');


INSERT INTO travelers (booking_id, first_name, last_name, date_of_birth, passport_number, passport_expiry_date,
                       nationality)
VALUES
-- Booking 1: John Smith + wife (2 people)
(1, 'John', 'Smith', '1985-05-20', 'US123456789', '2028-05-20', 'USA'),
(1, 'Mary', 'Smith', '1987-08-15', 'US987654321', '2029-08-15', 'USA'),
-- Booking 2: Emma Johnson + partner (2 people)
(2, 'Emma', 'Johnson', '1990-03-12', 'US234567890', '2027-03-12', 'USA'),
(2, 'Robert', 'Davis', '1988-11-25', 'US345678901', '2028-11-25', 'USA'),
-- Booking 3: Michael Brown family (3 people, 1 child)
(3, 'Michael', 'Brown', '1982-07-08', 'US456789012', '2026-07-08', 'USA'),
(3, 'Lisa', 'Brown', '1984-12-03', 'US567890123', '2027-12-03', 'USA'),
(3, 'Tommy', 'Brown', '2014-04-22', 'US678901234', '2026-04-22', 'USA'),
-- Booking 4: Sophia Garcia + friend (2 people)
(4, 'Sophia', 'Garcia', '1992-09-17', 'US789012345', '2029-09-17', 'USA'),
(4, 'Isabella', 'Rodriguez', '1993-02-28', 'US890123456', '2028-02-28', 'USA'),
-- Booking 5: James Wilson family (4 people)
(5, 'James', 'Wilson', '1980-06-14', 'US901234567', '2027-06-14', 'USA'),
(5, 'Patricia', 'Wilson', '1981-10-30', 'US012345678', '2026-10-30', 'USA'),
(5, 'Jessica', 'Wilson', '2008-03-15', 'US112345678', '2026-03-15', 'USA'),
(5, 'Kevin', 'Wilson', '2010-07-20', 'US212345678', '2027-07-20', 'USA'),
-- Booking 6: completed trip (2 people)
(6, 'John', 'Smith', '1985-05-20', 'US123456789', '2028-05-20', 'USA'),
(6, 'Mary', 'Smith', '1987-08-15', 'US987654321', '2029-08-15', 'USA'),
-- Booking 7: completed trip (2 people)
(7, 'Michael', 'Brown', '1982-07-08', 'US456789012', '2026-07-08', 'USA'),
(7, 'Lisa', 'Brown', '1984-12-03', 'US567890123', '2027-12-03', 'USA'),
-- Booking 8: cancelled (2 people)
(8, 'Emma', 'Johnson', '1990-03-12', 'US234567890', '2027-03-12', 'USA'),
(8, 'Robert', 'Davis', '1988-11-25', 'US345678901', '2028-11-25', 'USA');


INSERT INTO booking_excursions (booking_id, excursion_id, number_of_participants, scheduled_date, total_price)
VALUES
-- Booking 1: European Grand Tour - 5 excursions
(1, 1, 2, '2025-06-02', 179.98),  -- Eiffel Tower
(1, 2, 2, '2025-06-03', 150.00),  -- Louvre
(1, 4, 2, '2025-06-05', 130.00),  -- Colosseum
(1, 5, 2, '2025-06-06', 170.00),  -- Vatican
(1, 6, 2, '2025-06-11', 159.98),  -- Sagrada Familia
-- Booking 2: Paris Romance - 2 excursions
(2, 1, 2, '2025-07-11', 179.98),  -- Eiffel Tower
(2, 3, 2, '2025-07-13', 299.98),  -- Versailles
-- Booking 3: Thailand Adventure - 4 excursions (family with child)
(3, 8, 3, '2025-08-16', 165.00),  -- Grand Palace
(3, 9, 3, '2025-08-17', 195.00),  -- Floating Market
(3, 10, 3, '2025-08-19', 360.00), -- Phi Phi Islands
(3, 11, 3, '2025-08-20', 285.00), -- James Bond Island
-- Booking 4: Italian Highlights - 2 excursions (pending)
(4, 4, 2, '2025-12-02', 130.00),  -- Colosseum
(4, 5, 2, '2025-12-03', 170.00),  -- Vatican
-- Booking 6: completed trip - 2 excursions
(6, 1, 2, '2024-08-16', 179.98),  -- Eiffel Tower
(6, 2, 2, '2024-08-17', 150.00); -- Louvre
