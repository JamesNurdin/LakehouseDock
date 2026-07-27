WITH sales_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        i.i_item_id,
        i.i_item_desc,
        concat(cp.cp_department, '-', CAST(cp.cp_catalog_number AS varchar)) AS dept_page,
        sum(cs.cs_net_paid_inc_ship) AS total_sales,
        count(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(i.i_item_desc, '(?i)steel|plastic')
      AND cp.cp_type LIKE 'A%'
      AND cd.cd_credit_rating = 'Excellent'
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        i.i_item_id,
        i.i_item_desc,
        concat(cp.cp_department, '-', CAST(cp.cp_catalog_number AS varchar))
),
returns_agg AS (
    SELECT
        i.i_item_id,
        sum(wr.wr_return_amt) AS total_returns,
        count(DISTINCT wr.wr_order_number) AS return_orders_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)steel|plastic')
      AND cd.cd_credit_rating = 'Excellent'
    GROUP BY i.i_item_id
)
SELECT
    s.cp_catalog_page_id,
    s.dept_page,
    s.i_item_id,
    substring(s.i_item_desc, 1, 30) AS item_desc_prefix,
    s.total_sales,
    coalesce(r.total_returns, 0) AS total_returns,
    s.orders_cnt,
    coalesce(r.return_orders_cnt, 0) AS return_orders_cnt,
    (s.total_sales - coalesce(r.total_returns, 0)) AS net_sales
FROM sales_agg s
LEFT JOIN returns_agg r ON s.i_item_id = r.i_item_id
ORDER BY s.total_sales DESC
LIMIT 100
