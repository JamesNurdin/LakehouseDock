WITH base AS (
    SELECT
        s.s_store_id,
        d_sales.d_date,
        i.i_category,
        ss.ss_net_paid,
        ss.ss_net_profit,
        RANK() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS sales_rank,
        (
            SELECT AVG(sr_sub.sr_return_quantity)
            FROM store_returns sr_sub
            WHERE sr_sub.sr_item_sk = ss.ss_item_sk
        ) AS avg_return_qty,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_level,
        w.web_name
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_returns ON sr.sr_returned_date_sk = d_returns.d_date_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w ON w.web_open_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2002
      AND i.i_brand = 'Brand#10'
      AND sm.sm_carrier = 'MSC'
      AND cd_sales.cd_gender = 'F'
      AND s.s_state = 'CA'
      AND w.web_country = 'United States'
)
SELECT *
FROM base
ORDER BY sales_rank, ss_net_profit DESC
LIMIT 100
