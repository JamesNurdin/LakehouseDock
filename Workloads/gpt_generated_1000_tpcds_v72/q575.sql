WITH base AS (
    SELECT
        d_sold.d_year,
        p.p_promo_name,
        sm.sm_type,
        SUM(cs.cs_net_profit)                         AS cs_profit,
        SUM(ss.ss_net_paid_inc_tax)                  AS ss_profit,
        SUM(ws.ws_net_profit)                        AS ws_profit,
        COUNT(DISTINCT cs.cs_order_number)           AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
       AND ss.ss_customer_sk = cust_bill.c_customer_sk
       AND ss.ss_cdemo_sk = cd_bill.cd_demo_sk
       AND ss.ss_hdemo_sk = hd_bill.hd_demo_sk
       AND ss.ss_addr_sk = ca_bill.ca_address_sk
       AND ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
       AND ws.ws_bill_customer_sk = cust_bill.c_customer_sk
       AND ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
       AND ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
       AND ws.ws_bill_addr_sk = ca_bill.ca_address_sk
       AND ws.ws_promo_sk = p.p_promo_sk
       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE p.p_purpose = 'Unknown'
      AND p.p_promo_id LIKE 'AAAAAAA%'
      AND d_sold.d_year BETWEEN 1999 AND 2001
      AND cust_bill.c_birth_country = 'United States'
      AND sm.sm_carrier = 'UPS'
      AND cp.cp_department = 'Sports'
      AND wsite.web_company_name LIKE 'able%'
    GROUP BY ROLLUP (d_sold.d_year, p.p_promo_name, sm.sm_type)
)
SELECT
    d_year,
    p_promo_name,
    sm_type,
    (cs_profit + ss_profit + ws_profit) AS total_profit,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (cs_profit + ss_profit + ws_profit) DESC) AS profit_rank
FROM base
ORDER BY d_year, profit_rank
LIMIT 100
