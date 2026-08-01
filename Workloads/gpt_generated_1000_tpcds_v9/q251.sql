WITH
    date_2001 AS (
        SELECT d_date_sk, d_date, d_year
        FROM date_dim
        WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    ),
    address_sample AS (
        SELECT *
        FROM customer_address
        TABLESAMPLE BERNOULLI (10)
    ),
    income_filtered AS (
        SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
        FROM income_band
        WHERE ib_lower_bound >= 50000
    ),
    household_filtered AS (
        SELECT hd_demo_sk, hd_income_band_sk, hd_dep_count, hd_buy_potential
        FROM household_demographics
        WHERE hd_dep_count = 1
          AND hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_filtered)
    ),
    promotion_filtered AS (
        SELECT p_promo_sk, p_promo_id, p_discount_active
        FROM promotion
        WHERE p_discount_active = 'Y'
          AND p_start_date_sk IN (SELECT d_date_sk FROM date_2001)
    ),
    catalog_sales_agg AS (
        SELECT
            cs.cs_order_number AS order_number,
            d.d_year,
            s.s_state AS state,
            SUM(cs.cs_net_paid) AS total_net_paid,
            AVG(cs.cs_ext_tax) AS avg_ext_tax,
            COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
        FROM catalog_sales cs
        JOIN date_2001 d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN address_sample ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN household_filtered hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN promotion_filtered p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        WHERE p.p_discount_active = 'Y'
        GROUP BY cs.cs_order_number, d.d_year, s.s_state
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_order_number AS order_number,
            d2.d_year,
            s2.s_state AS state,
            SUM(ws.ws_net_paid) AS total_net_paid,
            AVG(ws.ws_ext_tax) AS avg_ext_tax,
            COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
        FROM web_sales ws
        JOIN date_2001 d2 ON ws.ws_sold_date_sk = d2.d_date_sk
        JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
        JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
        JOIN address_sample ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
        JOIN household_filtered hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
        JOIN promotion_filtered p2 ON ws.ws_promo_sk = p2.p_promo_sk
        JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
        JOIN store s2 ON s2.s_closed_date_sk = d2.d_date_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_item_sk = ws.ws_item_sk
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE p2.p_discount_active = 'Y'
        GROUP BY ws.ws_order_number, d2.d_year, s2.s_state
    ),
    common_orders AS (
        SELECT cs.cs_order_number AS order_number
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_2001)
        INTERSECT
        SELECT ws.ws_order_number
        FROM web_sales ws
        WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_2001)
    )
SELECT
    combined.order_number,
    combined.d_year,
    combined.state,
    combined.total_net_paid,
    combined.avg_ext_tax,
    combined.distinct_items,
    CASE
        WHEN combined.total_net_paid > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS revenue_category
FROM (
    SELECT order_number, d_year, state, total_net_paid, avg_ext_tax, distinct_items
    FROM catalog_sales_agg
    UNION ALL
    SELECT order_number, d_year, state, total_net_paid, avg_ext_tax, distinct_items
    FROM web_sales_agg
) AS combined
WHERE combined.order_number IN (SELECT order_number FROM common_orders)
ORDER BY combined.total_net_paid DESC
OFFSET 0
LIMIT 100
