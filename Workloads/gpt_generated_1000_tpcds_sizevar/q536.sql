-- Goal: Summarize yearly profit/loss by call center, gender and state, combining sales and return data, applying multiple filters, a CASE expression, a window rank, a correlated EXISTS check, and a UNION of two distinct selects.
WITH sales_data AS (
    SELECT
        d.d_date_sk,
        cc.cc_name,
        cd.cd_gender,
        ca.ca_state,
        ss.ss_ext_sales_price AS amount,
        'sales' AS src
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cc.cc_manager = 'Charles Hinkle'
      AND inv.inv_quantity_on_hand > 600
      AND ss.ss_quantity > 0
      AND ss.ss_ext_sales_price > 200
      AND ca.ca_gmt_offset BETWEEN -6 AND -4
      AND cd.cd_education_status = 'College'
),
returns_data AS (
    SELECT
        d.d_date_sk,
        cd.cd_gender,
        ca.ca_state,
        cr.cr_net_loss * -1 AS amount,
        'catalog' AS src
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cr.cr_fee > 20
      AND cc.cc_tax_percentage < 5
      AND cr.cr_return_quantity > 0
      AND cd.cd_gender = 'M'
      AND ca.ca_state IS NOT NULL
    UNION DISTINCT
    SELECT
        d.d_date_sk,
        cd.cd_gender,
        ca.ca_state,
        wr.wr_net_loss * -1 AS amount,
        'web' AS src
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wp.wp_type = 'article'
      AND wr.wr_fee > 5
      AND cd.cd_gender = 'F'
      AND ca.ca_state IS NOT NULL
)
SELECT
    u.d_year,
    u.cc_name,
    u.gender,
    u.state,
    SUM(u.amount) AS total_amount,
    CASE WHEN SUM(u.amount) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator,
    RANK() OVER (PARTITION BY u.d_year ORDER BY SUM(u.amount) DESC) AS revenue_rank
FROM (
    SELECT
        d.d_year,
        sd.cc_name,
        sd.cd_gender AS gender,
        sd.ca_state AS state,
        sd.amount
    FROM sales_data sd
    JOIN date_dim d ON sd.d_date_sk = d.d_date_sk
    UNION DISTINCT
    SELECT
        d.d_year,
        NULL AS cc_name,
        rd.cd_gender AS gender,
        rd.ca_state AS state,
        rd.amount
    FROM returns_data rd
    JOIN date_dim d ON rd.d_date_sk = d.d_date_sk
) u
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    JOIN date_dim d2 ON inv2.inv_date_sk = d2.d_date_sk
    WHERE d2.d_year = u.d_year
      AND inv2.inv_quantity_on_hand > 500
)
GROUP BY u.d_year, u.cc_name, u.gender, u.state
HAVING SUM(u.amount) <> 0
ORDER BY u.d_year, revenue_rank
LIMIT 100
