drop table if exists board;
drop function if exists NewGame();
drop function if exists NextMove(px int, py int);

create table board
(
    x   int check ( x between 1 and 3),      --row
    y   int check ( y between 1 and 3),      --col
    val char(1) check ( val in ('X', 'O') ), --val
    primary key (x, y)
);

create or replace function NewGame()
    returns text
    language plpgsql
as
$$
begin
    truncate board; --clear desk
    insert into board (x, y)
    select row, col
    from generate_series(1, 3) row,
         generate_series(1, 3) col;
    return 'Игра началась. Игрок X ходит первым.';
end;

$$;



create or replace function NextMove(px int, py int)
    returns text
    language plpgsql
as
$$
declare
    cur_val    char(1); --current symbol
    is_win     boolean; --win flag
    is_draw    boolean; --draw flag
    board_view text; --board visual
begin
    if (px not between 1 and 3) or (py not between 1 and 3) then
        return 'ошибка - координаты должны быть от 1 до 3.';
    end if;

    if exists (select 1 from board where x = px and y = py and val is not null) then
        return 'ошибка - клетка занята.';
    end if;

    --check which turn
    select case when count(*) % 2 = 0 then 'X' else 'O' end
    into cur_val
    from board
    where val is not null;

    update board set val = cur_val where x = px and y = py;

    select exists (select 1
                   from (select count(*) cnt
                         from board
                         where val = cur_val
                           and x = px --row
                         union all
                         select count(*) cnt
                         from board
                         where val = cur_val
                           and y = py --col
                         union all
                         select count(*) cnt
                         from board
                         where val = cur_val
                           and x = y
                           and px = py --diag 1
                         union all
                         select count(*) cnt
                         from board
                         where val = cur_val
                           and x + y = 4
                           and px + py = 4 --diag 2
                        ) checks
                   where cnt = 3)
    into is_win;

    --test for draw
    select count(*) = 9 into is_draw from board where val is not null;

    --generate board
    select string_agg(row_str, E'\n---+---+---\n')
    into board_view
    from (select x, string_agg(coalesce(val, ' '), ' | ' order by y) as row_str
          from board
          group by x
          order by x) t;

    return case
               when is_win then E'\nИгра окончена: победитель ' || cur_val || E'.\n\n' || board_view
               when is_draw then E'\nИгра окончена: ничья.\n\n' || board_view
               else E'\n' || board_view
        end;
end;


$$;

--test
select NewGame();
select NextMove(3, 1);