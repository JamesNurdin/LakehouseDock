WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_profit,
        cs.cs_warehouse_sk AS sales_warehouse_sk,
        cs.cs_promo_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_warehouse_sk AS return_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_item_sk,
        cr.cr_returned_time_sk,
        cr.cr_catalog_page_sk,
        p.p_promo_name,
        w_sales.w_warehouse_name AS sales_warehouse_name,
        w_return.w_warehouse_name AS return_warehouse_name,
        t_sold.t_hour,
        t_return.t_hour AS return_hour,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp_sales
      ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
    JOIN warehouse w_sales
      ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
      ON cs.cs_item_sk = cr.cr_item_sk
     AND cs.cs_order_number = cr.cr_order_number
    JOIN time_dim t_return
      ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN catalog_page cp_return
      ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
    JOIN warehouse w_return
      ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
)
SELECT
    s.p_promo_name,
    s.sales_warehouse_name,
    SUM(s.cs_net_profit) AS total_sales_profit,
    SUM(s.cr_net_loss) AS total_return_loss,
    (SUM(s.cs_net_profit) - SUM(s.cr_net_loss)) AS net_contribution,
    CASE
        WHEN (SUM(s.cs_net_profit) - SUM(s.cr_net_loss)) > 10000 THEN 'High'
        WHEN (SUM(s.cs_net_profit) - SUM(s.cr_net_loss)) BETWEEN 1000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (
        SELECT AVG(cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_warehouse_sk = s.sales_warehouse_sk
    ) AS avg_return_amount_for_warehouse
FROM sales_returns s
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr_ex
    JOIN reason r_ex ON cr_ex.cr_reason_sk = r_ex.r_reason_sk
    WHERE cr_ex.cr_warehouse_sk = s.sales_warehouse_sk
      AND r_ex.r_reason_desc = 'Not working any more'
)
GROUP BY
    s.p_promo_name,
    s.sales_warehouse_name,
    s.sales_warehouse_sk
ORDER BY net_contribution DESC
LIMIT 100
