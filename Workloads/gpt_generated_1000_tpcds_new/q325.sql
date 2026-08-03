WITH sampled_catalog_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
base AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_number,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        c.c_customer_id,
        c.c_birth_year,
        hd_bill.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_id,
        s.s_store_name,
        s.s_state,
        sr.sr_return_amt,
        ws.ws_net_paid,
        inv.inv_quantity_on_hand,
        ARRAY[CAST(cs.cs_quantity AS double), CAST(cs.cs_ext_sales_price AS double)] AS metrics_arr
    FROM sampled_catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_item_sk = ws.ws_item_sk
    WHERE cp.cp_department = 'Books'
      AND ib.ib_upper_bound >= 100000
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND s.s_state = 'CA'
      AND ws.ws_sold_date_sk = 2451060
),
base_unnested AS (
    SELECT
        b.*, 
        u.metric_value,
        CASE WHEN u.idx = 1 THEN 'quantity' ELSE 'sales_price' END AS metric_type
    FROM base b
    CROSS JOIN UNNEST(b.metrics_arr) WITH ORDINALITY AS u(metric_value, idx)
),
agg AS (
    SELECT
        s_store_name,
        s_state,
        metric_type,
        SUM(metric_value) AS metric_sum
    FROM base_unnested
    GROUP BY s_store_name, s_state, metric_type
),
ranked AS (
    SELECT
        s_store_name,
        s_state,
        metric_type,
        metric_sum,
        ROW_NUMBER() OVER (PARTITION BY s_state, metric_type ORDER BY metric_sum DESC) AS rn
    FROM agg
)
SELECT
    s_store_name,
    s_state,
    metric_type,
    metric_sum
FROM ranked
WHERE rn <= 5
ORDER BY s_state, metric_type, metric_sum DESC
LIMIT 100
