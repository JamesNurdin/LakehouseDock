WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_year,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_manufact_id,
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state,
        cp.cp_department,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2002
      AND i.i_manufact_id IN (294, 86)
      AND ca.ca_state = 'CA'
      AND cp.cp_department = 'Sports'
      AND c.c_birth_month IN (3, 6, 10)
      AND cs.cs_quantity > 0
      AND hd.hd_buy_potential = '1001-5000'
      AND hd.hd_dep_count BETWEEN 1 AND 4
)
SELECT
    sb.d_year,
    sb.i_item_id,
    sb.i_product_name,
    sb.c_customer_id,
    sb.ca_state,
    sb.cp_department,
    sb.cs_quantity,
    sb.cs_ext_sales_price,
    sb.cs_net_profit,
    sr.sr_return_quantity,
    wr.wr_return_quantity,
    CASE WHEN sr.sr_return_quantity IS NOT NULL THEN 'Store Return' ELSE 'No Store Return' END AS store_return_flag,
    CASE WHEN wr.wr_return_quantity IS NOT NULL THEN 'Web Return' ELSE 'No Web Return' END AS web_return_flag,
    sr_r.r_reason_desc AS store_return_reason,
    wr_r.r_reason_desc AS web_return_reason,
    ROW_NUMBER() OVER (PARTITION BY sb.i_item_id ORDER BY sb.cs_ext_sales_price DESC) AS sales_rank,
    RANK() OVER (PARTITION BY sb.c_customer_id ORDER BY sb.cs_ext_sales_price DESC) AS customer_sales_rank,
    SUM(sb.cs_ext_sales_price) OVER (PARTITION BY sb.c_customer_id ORDER BY sb.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_customer,
    AVG(sb.cs_ext_sales_price) OVER (PARTITION BY sb.i_product_name ORDER BY sb.d_year ROWS 3 PRECEDING) AS moving_avg_price_last_4_years
FROM sales_base sb
LEFT JOIN store_returns sr
     ON sr.sr_item_sk = sb.i_item_sk
    AND sr.sr_returned_date_sk = sb.cs_sold_date_sk
LEFT JOIN reason sr_r
     ON sr.sr_reason_sk = sr_r.r_reason_sk
LEFT JOIN web_returns wr
     ON wr.wr_item_sk = sb.i_item_sk
    AND wr.wr_returned_date_sk = sb.cs_sold_date_sk
LEFT JOIN reason wr_r
     ON wr.wr_reason_sk = wr_r.r_reason_sk
LEFT JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d_wp
     ON wp.wp_access_date_sk = d_wp.d_date_sk
LEFT JOIN web_site ws
     ON ws.web_open_date_sk = d_wp.d_date_sk
WHERE sb.cs_ext_sales_price > 0
  AND (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity > 0)
  AND (wr.wr_return_quantity IS NULL OR wr.wr_return_quantity > 0)
  AND ws.web_state = 'CA'
  AND wp.wp_type = 'Content'
LIMIT 100
