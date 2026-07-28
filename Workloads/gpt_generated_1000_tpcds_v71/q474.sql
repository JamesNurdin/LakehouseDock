WITH sales_raw AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        d.d_year,
        cc.cc_call_center_id,
        cc.cc_name,
        regexp_extract(cc.cc_name, '(\\w+)$') AS cc_name_suffix,
        cp.cp_description,
        CASE WHEN regexp_like(cp.cp_description, '.*[Ee]lectronic.*') THEN 'Electronics' ELSE 'Other' END AS category,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        c.c_customer_id,
        cd.cd_demo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        CONCAT(cc.cc_name, ' - ', cp.cp_description) AS cc_desc_concat
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cc.cc_name, '^A+')
      AND cp.cp_description LIKE '%electronic%'
),
agg AS (
    SELECT
        cc_call_center_id,
        cc_name_suffix,
        d_year,
        category,
        cd_demo_sk,
        COUNT(*) AS sales_cnt,
        SUM(cs_quantity) AS total_qty,
        SUM(cs_net_paid) AS total_net_paid,
        AVG(cs_net_paid) AS avg_net_paid,
        SUM(CASE WHEN cs_net_profit > 0 THEN cs_net_paid ELSE 0 END) AS profit_net_paid,
        (SELECT AVG(cs2.cs_net_paid) FROM catalog_sales cs2 WHERE cs2.cs_bill_cdemo_sk = cd_demo_sk) AS avg_demo_net_paid
    FROM sales_raw
    WHERE EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_order_number = sales_raw.cs_order_number
          AND cr.cr_return_quantity > 0
    )
    GROUP BY cc_call_center_id, cc_name_suffix, d_year, category, cd_demo_sk
)
SELECT
    cc_call_center_id,
    cc_name_suffix,
    d_year,
    category,
    sales_cnt,
    total_qty,
    total_net_paid,
    avg_net_paid,
    profit_net_paid,
    avg_demo_net_paid,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS yearly_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
