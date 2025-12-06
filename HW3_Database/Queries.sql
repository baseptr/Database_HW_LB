/*Write a query that will return
for each year the most popular rental film among
films released in one year.*/
select release_year, title, rental_count
from (select f.release_year,
             f.title,
             count(r.rental_id)                                                         as rental_count,
             rank() over (partition by f.release_year order by count(r.rental_id) desc) as rn
      from film f
               join inventory inv on f.film_id = inv.film_id
               join rental r on inv.inventory_id = r.inventory_id
      group by f.release_year, f.title) sq
where rn = 1;


/*Write a query that will return the
Top-5 actors who have appeared in Comedies more than anyone else.*/
select act.first_name, act.last_name, count(*) as comedy_count
from actor act
         join film_actor fa on act.actor_id = fa.actor_id
         join film_category fc on fa.film_id = fc.film_id
         join category cat on fc.category_id = cat.category_id
where cat.name = 'Comedy'
group by act.actor_id, act.first_name, act.last_name
order by comedy_count desc
limit 5;


/*Write a query that will return the names
of actors who have not starred in “Action” films.*/
select first_name, last_name
from actor
where actor_id not in (select fa.actor_id
                       from film_actor fa
                                join film_category fc on fa.film_id = fc.film_id
                                join category cat on fc.category_id = cat.category_id
                       where cat.name = 'Action');


/*Write a query that will return the three most popular rental films by each genre.*/
select category_name, title, rental_count
from (select cat.name                                                                      category_name,
             f.title,
             count(r.rental_id)                                                            rental_count,
             row_number() over (partition by cat.name order by count(r.rental_id) desc) as rn
      FROM category cat
               join film_category fc on cat.category_id = fc.category_id
               join film f on fc.film_id = f.film_id
               join inventory inv on f.film_id = inv.film_id
               join rental r on inv.inventory_id = r.inventory_id
      group by cat.name, f.title) subquery
where rn <= 3
order by category_name, rental_count desc;


/*Calculate the number of films
released each year and cumulative total by the number of films.*/
select release_year,
       count(*)                                   as films_per_year,
       sum(count(*)) over (order by release_year) as cumulative_films
from film
group by release_year
order by release_year;


/*Calculate a monthly statistic based on “rental_date” field from “Rental” table
that for each month will show the percentage of “Animation” films
from the total number of rentals.*/
select to_char(r.rental_date, 'YYYY-MM')                       as rental_month,
       count(*)                                                as total_rentals,
       sum(case when cat.name = 'Animation' then 1 else 0 end) as animation_rentals,
       round(
               (sum(case when cat.name = 'Animation' then 1 else 0 end) * 100.0 / count(*)), 2
       )                                                       as animation_percentage
FROM rental r
         join inventory inv on r.inventory_id = inv.inventory_id
         join film_category fc on inv.film_id = fc.film_id
         join category cat on fc.category_id = cat.category_id
group by to_char(r.rental_date, 'YYYY-MM')
order by rental_month;


/*Write a query that will return the names of actors
who have starred in “Action” films more than in “Drama” film.*/
select act.first_name,
       act.last_name
from actor act
         join film_actor fa on act.actor_id = fa.actor_id
         join film_category fc on fa.film_id = fc.film_id
         join category cat on fc.category_id = cat.category_id
group by act.actor_id, act.first_name, act.last_name
having sum(case when cat.name = 'Action' then 1 else 0 end) >
       sum(case when cat.name = 'Drama' then 1 else 0 end);


/*Write a query that will return the top-5 customers
who spent the most money watching Comedies.*/
select cust.first_name,
       cust.last_name,
       sum(p.amount) as total_spent
from payment p
         join rental r on p.rental_id = r.rental_id
         join inventory inv on r.inventory_id = inv.inventory_id
         join film_category fc on inv.film_id = fc.film_id
         join category cat on fc.category_id = cat.category_id
         join customer cust on p.customer_id = cust.customer_id
where cat.name = 'Comedy'
group by cust.customer_id, cust.first_name, cust.last_name
order by total_spent desc
limit 5;


/*In the “Address” table, in the “address” field,
the last word indicates the "type" of a street: Street, Lane, Way, etc.
Write a query that will return all "types" of streets
and the number of addresses related to this "type".*/
select trim(substring(address from '\s(\S+)$')) as street_type,
       count(*)                                 as address_count
from address
group by street_type
order by address_count desc;


/*Write a query that will return a list of movie ratings,
indicate for each rating the total number of films with this rating,
the top-3 categories by the number of films in this category
and the number of films in this category with this rating.*/
select base_stats.rating,
       total_stats.total_films,
       max(case
               when base_stats.rn = 1
                   then base_stats.category_name || ': ' || base_stats.films_in_category end) as category1,
       max(case
               when base_stats.rn = 2
                   then base_stats.category_name || ': ' || base_stats.films_in_category end) as category2,
       max(case
               when base_stats.rn = 3
                   then base_stats.category_name || ': ' || base_stats.films_in_category end) as category3
from (
         -- select 2 ranging category in rating
         select rating,
                category_name,
                films_in_category,
                row_number() over (partition by rating order by films_in_category desc) as rn
         from (
                  -- select 1 count quantity of films by category and rating
                  select f.rating,
                         cat.name as category_name,
                         count(*) as films_in_category
                  from film f
                           join film_category fc on f.film_id = fc.film_id
                           join category cat on fc.category_id = cat.category_id
                  group by f.rating, cat.name) counts_sub) base_stats
         join (
    -- all quantity of films by rating
    select rating, count(*) as total_films
    from film
    group by rating) total_stats on base_stats.rating = total_stats.rating
group by base_stats.rating, total_stats.total_films
order by total_stats.total_films desc;