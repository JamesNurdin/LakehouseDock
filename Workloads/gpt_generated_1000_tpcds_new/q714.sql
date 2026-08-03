WITH returns_combined AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_addr_sk,
        wr.wr_web_page_sk
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr
        ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
        AND sr.sr_item_sk = wr.wr_item_sk
)
SELECT
    d.d_year,
    i.i_item_id,
    s.s_store_name,
    SUM(cs.cs_ext_sales_price)                                   AS total_sales,
    SUM(cs.cs_net_profit)                                        AS total_profit,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank,
    COUNT(DISTINCT c.c_customer_id)                             AS unique_customers,
    CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END   AS region_flag,
    src.source,
    src.profit_component
FROM catalog_sales cs
JOIN date_dim d          ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t          ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN warehouse w         ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i              ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p         ON cs.cs_promo_sk = p.p_promo_sk
JOIN returns_combined rc ON rc.sr_item_sk = cs.cs_item_sk
JOIN store s             ON rc.sr_store_sk = s.s_store_sk
JOIN web_page wp         ON rc.wr_web_page_sk = wp.wp_web_page_sk
JOIN inventory inv       ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
                         AND inv.inv_date_sk = d.d_date_sk
CROSS JOIN UNNEST(
    MAP(
        ARRAY['store','web'],
        ARRAY[cs.cs_net_profit, cs.cs_net_profit * 0.9]
    )
) AS src(source, profit_component)
WHERE d.d_year = 2001
  AND i.i_color = 'Red'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND cs.cs_quantity > 1
GROUP BY
    d.d_year,
    i.i_item_id,
    s.s_store_name,
    s.s_state,
    src.source,
    src.profit_component
HAVING SUM(cs.cs_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
