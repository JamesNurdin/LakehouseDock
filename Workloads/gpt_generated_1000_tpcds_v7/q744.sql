WITH sales_agg AS (
        SELECT
            cs_item_sk,
            cs_warehouse_sk,
            cs_order_number,
            SUM(cs_ext_sales_price) AS total_sales,
            SUM(cs_net_profit) AS total_profit
        FROM tpcds.catalog_sales
        WHERE cs_ext_sales_price > 500
          AND cs_list_price < 200
        GROUP BY cs_item_sk, cs_warehouse_sk, cs_order_number
    ),
    returns_agg AS (
        SELECT
            cr_item_sk,
            cr_warehouse_sk,
            cr_reason_sk,
            cr_order_number,
            SUM(cr_net_loss) AS total_net_loss,
            SUM(cr_return_quantity) AS total_return_qty
        FROM tpcds.catalog_returns
        WHERE cr_return_quantity > 1
          AND cr_return_amount > 100
        GROUP BY cr_item_sk, cr_warehouse_sk, cr_reason_sk, cr_order_number
    )
SELECT
    w.w_warehouse_name,
    w.w_city,
    r.r_reason_desc,
    ra.total_net_loss,
    sa.total_sales,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY ra.total_net_loss DESC) AS loss_rank,
    SUM(sa.total_sales) OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY ra.total_net_loss DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_loss
FROM sales_agg sa
JOIN returns_agg ra
     ON sa.cs_item_sk = ra.cr_item_sk
    AND sa.cs_warehouse_sk = ra.cr_warehouse_sk
    AND sa.cs_order_number = ra.cr_order_number
JOIN tpcds.warehouse w
     ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.reason r
     ON ra.cr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%missing%'
  AND w.w_state = 'CA'
  AND sa.total_sales > 2000
ORDER BY loss_rank
LIMIT 100
