SELECT
    s.s_store_name,
    i.i_brand,
    d_sales.d_year,
    p.p_promo_name,
    cc.cc_company_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(ss.ss_ext_discount_amt) AS max_discount_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    MIN(sr.sr_return_quantity) AS min_return_quantity,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales
FROM store_sales ss
INNER JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
INNER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
INNER JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
INNER JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
INNER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
INNER JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
INNER JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
INNER JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
INNER JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_promo_sk = p.p_promo_sk
INNER JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
INNER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
INNER JOIN web_site w
    ON w.web_open_date_sk = d_sales.d_date_sk
WHERE s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND d_sales.d_year = 2001
  AND cc.cc_company = 3
GROUP BY
    s.s_store_name,
    i.i_brand,
    d_sales.d_year,
    p.p_promo_name,
    cc.cc_company_name
LIMIT 100
