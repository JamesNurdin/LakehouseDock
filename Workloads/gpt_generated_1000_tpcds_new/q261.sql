WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        c.c_customer_id,
        c.c_customer_sk,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_item_id,
        i.i_brand,
        p.p_promo_id,
        td.t_hour,
        cp.cp_department
    FROM sampled_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cp.cp_department = 'Books'
      AND i.i_brand = 'Brand#23'
      AND p.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 40000
      AND td.t_hour BETWEEN 8 AND 12
),
aggregated_per_customer AS (
    SELECT
        c_customer_id,
        c_customer_sk,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(COALESCE(ws_net_profit, 0)) AS total_web_profit,
        COUNT(DISTINCT i_item_id) AS distinct_items,
        MIN(ib_lower_bound) AS min_income_lower,
        MAX(ib_upper_bound) AS max_income_upper
    FROM joined_data
    GROUP BY c_customer_id, c_customer_sk
),
return_set AS (
    SELECT cr_refunded_customer_sk AS cust_sk, SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_refunded_customer_sk
),
union_agg AS (
    SELECT c_customer_id AS cust_id, total_catalog_profit AS profit
    FROM aggregated_per_customer
    UNION
    SELECT c.c_customer_id AS cust_id, r.total_return_amount AS profit
    FROM customer c
    JOIN return_set r ON r.cust_sk = c.c_customer_sk
)
SELECT
    u.cust_id,
    AVG(u.profit) AS avg_profit,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
    ) AS total_refunded_amount
FROM union_agg u
JOIN customer c ON c.c_customer_id = u.cust_id
WHERE u.profit > 0
GROUP BY u.cust_id, c.c_customer_sk
HAVING AVG(u.profit) > 1000
EXCEPT
SELECT
    u2.cust_id,
    AVG(u2.profit) AS avg_profit,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c2.c_customer_sk
    ) AS total_refunded_amount
FROM union_agg u2
JOIN customer c2 ON c2.c_customer_id = u2.cust_id
WHERE u2.profit < 0
GROUP BY u2.cust_id, c2.c_customer_sk
LIMIT 100
