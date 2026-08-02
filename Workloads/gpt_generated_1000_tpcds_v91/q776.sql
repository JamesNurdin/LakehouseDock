WITH sales_stores AS (
    SELECT DISTINCT s.s_store_sk,
                    s.s_store_id,
                    s.s_store_name
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN date_dim d_close
        ON s.s_closed_date_sk = d_close.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d_close.d_date_sk
    WHERE d_sales.d_year = 2001
      AND d_sales.d_holiday = 'Y'
      AND ss.ss_net_profit > (
          SELECT AVG(ss2.ss_net_profit)
          FROM store_sales ss2
          JOIN date_dim d2
               ON ss2.ss_sold_date_sk = d2.d_date_sk
          WHERE d2.d_year = 2001
      )
      AND s.s_market_manager = 'John Miller'
),
returns_stores AS (
    SELECT DISTINCT s.s_store_sk,
                    s.s_store_id,
                    s.s_store_name
    FROM store s
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_close2
        ON s.s_closed_date_sk = d_close2.d_date_sk
    JOIN web_site w2
        ON w2.web_open_date_sk = d_close2.d_date_sk
    WHERE d_ret.d_year = 2001
      AND d_ret.d_holiday = 'Y'
      AND s.s_market_manager = 'John Miller'
)
SELECT s.s_store_id AS store_id,
       s.s_store_name AS store_name
FROM sales_stores s
INTERSECT
SELECT r.s_store_id,
       r.s_store_name
FROM returns_stores r
ORDER BY store_id
LIMIT 100
