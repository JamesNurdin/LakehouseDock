WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ARRAY[cs.cs_quantity, cs.cs_ext_sales_price] AS metrics_array
    FROM catalog_sales cs
    FULL OUTER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2451200               -- filter on surrogate date key
      AND c.c_birth_year BETWEEN 1950 AND 1960                         -- filter on customer age range
      AND cs.cs_net_paid > 1000                                       -- filter on high‑value sales
)
SELECT
    cp.cp_catalog_page_id,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    p.p_promo_name,
    w.w_warehouse_name,
    td.t_hour,
    sb.cs_quantity,
    sb.cs_ext_sales_price,
    metric_value,
    RANK() OVER (PARTITION BY i.i_category ORDER BY sb.cs_net_paid DESC) AS category_sales_rank,
    CASE WHEN sb.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    wr.wr_return_amt,
    r.r_reason_desc,
    wp.wp_url
FROM sales_base sb
JOIN time_dim td
    ON sb.cs_sold_time_sk = td.t_time_sk
JOIN item i
    ON sb.cs_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
    ON sb.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON sb.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON sb.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
    ON sb.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON sb.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_time_sk = td.t_time_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_time_sk = td.t_time_sk
LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
CROSS JOIN UNNEST(sb.metrics_array) AS u(metric_value)
WHERE wp.wp_autogen_flag = 'N'                -- additional filter on web page flag
ORDER BY sb.cs_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
