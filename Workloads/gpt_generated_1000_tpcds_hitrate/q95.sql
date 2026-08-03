WITH joined AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_number,
        sm.sm_type,
        sm.sm_code,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cs.cs_list_price,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
)
SELECT
    cp_department,
    cp_catalog_page_number,
    sm_type,
    sm_code,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    (SUM(cs_net_profit) - SUM(cr_net_loss)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (SUM(cs_net_profit) - SUM(cr_net_loss)) DESC) AS profit_rank
FROM joined
WHERE cp_catalog_page_number IN (7, 14, 21, 9)
  AND sm_code = 'AIR'
  AND cs_list_price > 50
  AND cs_ext_discount_amt < 2000
GROUP BY CUBE (cp_department, sm_type, sm_code, cp_catalog_page_number)
HAVING SUM(cs_ext_sales_price) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
