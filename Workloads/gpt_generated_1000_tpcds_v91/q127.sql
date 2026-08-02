WITH store_sales_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_promo_sk,
        SUM(ss_net_paid) AS store_net_paid,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    WHERE ss_quantity > 5
      AND ss_net_paid > 0
    GROUP BY ss_sold_date_sk, ss_promo_sk
    HAVING SUM(ss_quantity) > 10
),
orders_no_returns AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 1
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
joined_data AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        w.w_warehouse_name,
        s.web_name,
        sa.store_net_paid,
        ws.ws_net_paid,
        ws.ws_order_number,
        (
            SELECT SUM(wr2.wr_return_amt)
            FROM web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
        ) AS total_return_amt
    FROM store_sales_agg sa
    JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                       AND ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    JOIN orders_no_returns onr ON ws.ws_order_number = onr.ws_order_number
    WHERE d.d_year = 2001
      AND p.p_cost > 20
      AND w.w_warehouse_sq_ft > 2000000
      AND s.web_mkt_id IN (1, 2, 3)
      AND ws.ws_net_paid > 100
)
SELECT
    d_year,
    p_promo_name,
    w_warehouse_name,
    web_name,
    SUM(store_net_paid) AS total_store_net_paid,
    SUM(ws_net_paid) AS total_web_net_paid,
    AVG(ws_net_paid) AS avg_ws_net_paid,
    SUM(total_return_amt) AS total_return_amount,
    COUNT(*) AS row_count
FROM joined_data
GROUP BY d_year, p_promo_name, w_warehouse_name, web_name
HAVING SUM(store_net_paid) > 1000
ORDER BY total_web_net_paid DESC
LIMIT 100
