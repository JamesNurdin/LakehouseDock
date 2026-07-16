WITH sales_returns AS (
    SELECT
        cp.cp_type,
        cp.cp_catalog_page_number,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_ext_sales_price) AS total_sales_price
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_page_number IN (1, 2, 3)
      AND cs.cs_sold_date_sk BETWEEN 2450905 AND 2451087
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY cp.cp_type, cp.cp_catalog_page_number, r.r_reason_desc
)
SELECT
    cp_type,
    cp_catalog_page_number,
    r_reason_desc,
    total_net_loss,
    total_net_profit,
    avg_discount_amt,
    distinct_orders,
    total_sales_price,
    total_net_loss / NULLIF(total_net_profit, 0) AS loss_to_profit_ratio,
    RANK() OVER (PARTITION BY cp_type ORDER BY total_net_loss DESC) AS loss_rank_within_type
FROM sales_returns
ORDER BY total_net_loss DESC
LIMIT 100
