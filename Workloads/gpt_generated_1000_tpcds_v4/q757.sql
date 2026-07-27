WITH date_filtered AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2002
      AND d_month_seq BETWEEN 1200 AND 1220
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    sr.sr_net_loss,
    wr.wr_net_loss,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_type,
    ws.web_name,
    inv.inv_quantity_on_hand,
    cp.cp_catalog_page_number,
    t.t_hour,
    r.r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank,
    (
        SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
          AND cs2.cs_sold_date_sk = d.d_date_sk
    ) AS item_total_sales
FROM date_filtered d
LEFT JOIN catalog_sales cs
       ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p
       ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
       ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
       ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN time_dim t
       ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr
       ON sr.sr_returned_date_sk = d.d_date_sk
      AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN reason r
       ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
       ON wr.wr_returned_date_sk = d.d_date_sk
      AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN web_page wp
       ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_site ws
       ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN inventory inv
       ON inv.inv_date_sk = d.d_date_sk
      AND inv.inv_item_sk = i.i_item_sk
WHERE
    i.i_current_price > 50
    AND ws.web_class = 'Unknown'
    AND p.p_discount_active = 'Y'
ORDER BY sales_rank
LIMIT 100
