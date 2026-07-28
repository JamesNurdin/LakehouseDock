WITH
    -- Filtered date dimension for the sold date
    d_sold AS (
        SELECT d_date_sk, d_date, d_year, d_month_seq
        FROM date_dim
        WHERE d_year = 2002
    ),
    -- Date dimension for store closed date (used for the join to store)
    d_closed AS (
        SELECT d_date_sk, d_date AS closed_date
        FROM date_dim
        WHERE d_year = 2002
    ),
    -- Date dimension for catalog page end date
    d_cp AS (
        SELECT d_date_sk, d_date AS cp_end_date
        FROM date_dim
        WHERE d_month_seq BETWEEN 1200 AND 1220
    )
SELECT
    ws.ws_order_number,
    d_sold.d_date AS sale_date,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    s.s_store_id,
    s.s_state,
    cd.cd_gender,
    CASE
        WHEN ws.ws_net_profit > 1000 THEN 'HIGH'
        WHEN ws.ws_net_profit > 0    THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ws.ws_ext_sales_price,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank_in_store,
    AVG(ws.ws_ext_sales_price) OVER (PARTITION BY i.i_item_id) AS avg_item_sales,
    (
        SELECT COUNT(*)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ws.ws_item_sk
          AND ws2.ws_sold_date_sk = ws.ws_sold_date_sk
    ) AS daily_item_sales_count,
    (
        SELECT SUM(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ws.ws_item_sk
    ) AS total_item_sales
FROM web_sales ws
JOIN d_sold          ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim td     ON ws.ws_sold_time_sk = td.t_time_sk
JOIN item i          ON ws.ws_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN store s         ON s.s_state IS NOT NULL                     -- cross‑join placeholder, real join via closed date below
JOIN d_closed        ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN catalog_page cp ON 1 = 1                                      -- cross‑join placeholder, real join via cp end date below
JOIN d_cp            ON cp.cp_end_date_sk = d_cp.d_date_sk
WHERE
    i.i_current_price BETWEEN 20 AND 100
    AND s.s_state = 'TX'
    AND cd.cd_gender = 'M'
    AND cp.cp_type = 'monthly'
    AND td.t_hour BETWEEN 8 AND 20
LIMIT 100
