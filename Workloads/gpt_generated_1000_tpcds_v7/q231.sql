SELECT
    ws.web_name,
    cp.cp_department,
    dd.d_year,
    dd.d_month_seq,
    sm.sm_type,
    SUM(cs.cs_ext_sales_price) AS total_extended_sales,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_count,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    MIN(cs.cs_quantity) AS min_quantity,
    MAX(cs.cs_quantity) AS max_quantity
FROM
    catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim dd
    ON cs.cs_sold_date_sk = dd.d_date_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN inventory inv
    ON inv.inv_date_sk = dd.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = dd.d_date_sk
   AND sr.sr_return_time_sk = td.t_time_sk
   AND sr.sr_cdemo_sk = cd.cd_demo_sk
   AND sr.sr_addr_sk = ca.ca_address_sk
JOIN web_site ws
    ON ws.web_open_date_sk = dd.d_date_sk
WHERE
    dd.d_year = 2001
    AND cp.cp_department = 'Books'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND cd.cd_gender = 'F'
    AND inv.inv_quantity_on_hand > 300
GROUP BY
    ws.web_name,
    cp.cp_department,
    dd.d_year,
    dd.d_month_seq,
    sm.sm_type
ORDER BY
    total_net_paid DESC
LIMIT 100
