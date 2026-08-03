WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_ship_mode_sk,
        cs_catalog_page_sk,
        cs_bill_addr_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_ext_sales_price) AS total_sales_amount
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs_quantity > 0
      AND cs_net_profit > 0
      AND cs_list_price > 10
      AND cs_wholesale_cost > 5
    GROUP BY cs_item_sk, cs_ship_mode_sk, cs_catalog_page_sk, cs_bill_addr_sk
),
returns_agg AS (
    SELECT
        wr_item_sk,
        wr_reason_sk,
        wr_web_page_sk,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_net_loss) AS total_return_loss
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND wr_return_quantity > 0
      AND wr_return_amt > 0
    GROUP BY wr_item_sk, wr_reason_sk, wr_web_page_sk
)
SELECT
    cp.cp_department,
    sm.sm_type,
    r.r_reason_desc,
    ca.ca_state,
    SUM(sa.total_sales_amount) AS sum_sales_amount,
    SUM(ra.total_return_loss) AS sum_return_loss,
    SUM(sa.total_sales_amount) - SUM(ra.total_return_loss) AS net_effect,
    CASE
        WHEN SUM(sa.total_sales_amount) - SUM(ra.total_return_loss) > 50000 THEN 'High'
        ELSE 'Low'
    END AS profit_category
FROM sales_agg sa
JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i ON sa.cs_item_sk = i.i_item_sk
JOIN customer_address ca ON sa.cs_bill_addr_sk = ca.ca_address_sk
JOIN returns_agg ra ON sa.cs_item_sk = ra.wr_item_sk
JOIN reason r ON ra.wr_reason_sk = r.r_reason_sk
JOIN web_page wp ON ra.wr_web_page_sk = wp.wp_web_page_sk
WHERE cp.cp_catalog_page_number IN (5, 11, 19)
  AND cp.cp_type = 'Promo'
  AND sm.sm_contract = 'HVDFCcQ'
  AND i.i_brand = 'BrandX'
  AND ca.ca_state = 'CA'
  AND r.r_reason_desc NOT LIKE '%size%'
GROUP BY CUBE (cp.cp_department, sm.sm_type, r.r_reason_desc, ca.ca_state)
ORDER BY net_effect DESC
LIMIT 100
