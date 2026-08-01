WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        d_sales.d_date,
        d_sales.d_year,
        t.t_hour,
        t.t_minute,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.s_store_name,
        s.s_state,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cp.cp_catalog_page_number,
        cp.cp_type,
        w.w_warehouse_name,
        w.w_state AS warehouse_state
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_returns cr
        ON cr.cr_returning_customer_sk = c.c_customer_sk
        AND cr.cr_returned_date_sk = d_sales.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d_sales.d_year = 2001
      AND s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_type = 'Promotion'
      AND w.w_state = 'CA'
),
store_agg AS (
    SELECT
        store_sk,
        s_store_name,
        s_state,
        d_year,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(cr_return_amount) AS total_returns,
        SUM(cr_net_loss) AS total_return_loss,
        SUM(ss_quantity) AS total_quantity,
        SUM(cr_return_quantity) AS total_return_quantity,
        CASE
            WHEN SUM(ss_net_profit) > 10000 THEN 'High'
            WHEN SUM(ss_net_profit) > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM base
    GROUP BY store_sk, s_store_name, s_state, d_year
)
SELECT
    s_store_name,
    s_state,
    d_year,
    total_sales,
    total_profit,
    total_returns,
    total_return_loss,
    profit_category,
    (total_profit - total_return_loss) AS net_profit_after_returns,
    (total_sales / NULLIF(total_quantity, 0)) AS avg_sale_price_per_item,
    (SELECT AVG(total_profit) FROM store_agg) AS avg_profit_all_stores
FROM store_agg
WHERE total_sales > 1000
  AND profit_category = 'High'
  AND EXISTS (
        SELECT 1
        FROM customer c2
        WHERE c2.c_customer_sk = (
            SELECT MIN(c3.c_customer_sk)
            FROM customer c3
            WHERE c3.c_last_name LIKE 'S%'
        )
    )
ORDER BY net_profit_after_returns DESC
LIMIT 100
