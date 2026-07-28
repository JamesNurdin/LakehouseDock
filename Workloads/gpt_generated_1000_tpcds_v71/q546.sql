WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_addr_sk,
        cs.cs_order_number,
        SUM(cs.cs_ext_sales_price)      AS total_sales,
        SUM(cs.cs_quantity)             AS total_quantity,
        COUNT(*)                        AS sales_cnt
    FROM catalog_sales cs
    GROUP BY
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_addr_sk,
        cs.cs_order_number
)
SELECT
    i.i_item_id,
    i.i_product_name,
    ds.d_date,
    cs.total_sales,
    cs.total_quantity,
    cs.sales_cnt,
    p.p_promo_name,
    cc.cc_name,
    s.s_store_name,
    SUM(cr.cr_return_amount)          AS total_return_amount,
    SUM(ws.ws_ext_sales_price)        AS total_web_sales,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY cs.total_sales DESC) AS sales_rank
FROM cs_agg cs
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim ds
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN time_dim ts
    ON cs.cs_sold_time_sk = ts.t_time_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = ds.d_date_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = ds.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = ds.d_date_sk
   AND ws.ws_sold_time_sk = ts.t_time_sk
WHERE
    i.i_class = 'dresses'                                   -- filter 1: product class
    AND ds.d_year = 2002                                    -- filter 2: year of sale
    AND cp.cp_catalog_number = 15                           -- filter 3: catalog number
    AND s.s_state = 'CA'                                    -- filter 4: store location
    AND ts.t_hour BETWEEN 9 AND 17                          -- filter 5: business hours
GROUP BY
    i.i_item_id,
    i.i_product_name,
    ds.d_date,
    cs.total_sales,
    cs.total_quantity,
    cs.sales_cnt,
    p.p_promo_name,
    cc.cc_name,
    s.s_store_name
ORDER BY
    cs.total_sales DESC,
    i.i_item_id
LIMIT 100
