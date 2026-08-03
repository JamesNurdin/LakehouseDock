WITH
    sampled_catalog_sales AS (
        SELECT *
        FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    ),
    sales_agg AS (
        SELECT cs_item_sk,
               SUM(cs_net_profit) AS total_profit,
               COUNT(*) AS sales_cnt
        FROM sampled_catalog_sales
        GROUP BY cs_item_sk
    ),
    item_not_in_web AS (
        SELECT cs_item_sk
        FROM (SELECT DISTINCT cs_item_sk FROM catalog_sales)
        EXCEPT
        SELECT DISTINCT ws_item_sk FROM web_sales
    )
SELECT
    d1.d_year,
    i.i_category,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(sa.total_profit) AS total_profit,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(ws.ws_net_paid) AS web_net_paid,
    COUNT(DISTINCT s.s_store_id) AS distinct_stores
FROM
    sales_agg sa
    JOIN item i
        ON sa.cs_item_sk = i.i_item_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d1
        ON cs.cs_sold_date_sk = d1.d_date_sk
    RIGHT OUTER JOIN store s
        ON s.s_closed_date_sk = d1.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN (
        SELECT *
        FROM catalog_returns TABLESAMPLE BERNOULLI (5)
    ) cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN warehouse w_cr
        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN warehouse w_inv
        ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN date_dim d2
        ON ws_site.web_open_date_sk = d2.d_date_sk
    LEFT JOIN item_not_in_web ini
        ON ini.cs_item_sk = i.i_item_sk
    LEFT JOIN LATERAL (
        SELECT ARRAY[ c.c_customer_id, c.c_email_address ] AS arr
    ) t ON TRUE
    LEFT JOIN UNNEST(t.arr) AS u(cust_val) ON TRUE
WHERE
    d1.d_holiday = 'N'
GROUP BY
    d1.d_year,
    i.i_category
LIMIT 100
