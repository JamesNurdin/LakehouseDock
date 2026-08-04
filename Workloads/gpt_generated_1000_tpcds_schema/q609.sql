WITH cs_cr AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    WHERE cs.cs_sold_date_sk BETWEEN 2450836 AND 2451102
),
order_excl AS (
    SELECT cs_order_number FROM catalog_sales
    EXCEPT
    SELECT ws_order_number FROM web_sales
),
base AS (
    SELECT
        cr.*,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        w.w_state,
        sm.sm_type,
        i.i_item_id,
        i.i_item_desc,
        cp.cp_department,
        cc.cc_name,
        ws.ws_order_number,
        wr.wr_order_number
    FROM cs_cr cr
    JOIN customer c
        ON cr.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc
        ON cr.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cr.cs_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE cd.cd_gender = 'M'
      AND ib.ib_upper_bound >= 50000
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cr.cs_order_number IN (SELECT cs_order_number FROM order_excl)
),
sampled AS (
    SELECT * FROM base TABLESAMPLE BERNOULLI (10)
),
exploded AS (
    SELECT
        s.c_customer_id,
        s.i_item_id,
        s.cp_department,
        s.cc_name,
        s.w_state,
        s.cs_quantity,
        s.cs_net_paid,
        s.cs_sold_date_sk,
        s.cs_order_number,
        word
    FROM sampled s
    CROSS JOIN UNNEST(split(s.i_item_desc, ' ')) AS t(word)
)
SELECT
    e.c_customer_id,
    e.i_item_id,
    e.word,
    e.cp_department,
    e.cc_name,
    e.w_state,
    SUM(e.cs_quantity) AS total_quantity,
    SUM(e.cs_net_paid) AS total_sales,
    COUNT(DISTINCT e.cs_order_number) AS distinct_orders,
    MIN(e.cs_sold_date_sk) AS first_sold_date,
    MAX(e.cs_sold_date_sk) AS last_sold_date,
    LAG(MIN(e.cs_sold_date_sk)) OVER (PARTITION BY e.c_customer_id ORDER BY MIN(e.cs_sold_date_sk)) AS prev_sold_date,
    SUM(SUM(e.cs_net_paid)) OVER (PARTITION BY e.w_state ORDER BY MIN(e.cs_sold_date_sk) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales_state
FROM exploded e
GROUP BY
    e.c_customer_id,
    e.i_item_id,
    e.word,
    e.cp_department,
    e.cc_name,
    e.w_state
ORDER BY total_sales DESC
LIMIT 100
