WITH
    ws_sample AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    web_base AS (
        SELECT
            ws.ws_sold_date_sk   AS wb_sold_date_sk,
            ws.ws_sold_time_sk   AS wb_sold_time_sk,
            ws.ws_web_site_sk    AS wb_web_site_sk,
            ws.ws_promo_sk       AS wb_promo_sk,
            ws.ws_bill_customer_sk AS wb_bill_customer_sk,
            d.d_year             AS wb_year,
            wsite.web_name       AS wb_web_name,
            p.p_promo_name       AS wb_promo_name,
            SUM(ws.ws_ext_sales_price) AS wb_total_sales,
            SUM(ws.ws_net_profit)       AS wb_total_profit,
            COUNT(*)                    AS wb_sales_cnt
        FROM ws_sample ws
        JOIN date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t   ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN promotion p  ON ws.ws_promo_sk = p.p_promo_sk
        JOIN customer c   ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE wsite.web_manager = 'Marshall Conner'
          AND wsite.web_zip = '14593'
          AND p.p_discount_active = 'Y'
          AND d.d_year BETWEEN 2000 AND 2002
          AND cd.cd_purchase_estimate >= 3000
          AND hd.hd_buy_potential = 'HIGH'
        GROUP BY ws.ws_sold_date_sk,
                 ws.ws_sold_time_sk,
                 ws.ws_web_site_sk,
                 ws.ws_promo_sk,
                 ws.ws_bill_customer_sk,
                 d.d_year,
                 wsite.web_name,
                 p.p_promo_name
    ),
    store_base AS (
        SELECT
            sr.sr_returned_date_sk AS sb_returned_date_sk,
            sr.sr_return_time_sk   AS sb_return_time_sk,
            sr.sr_customer_sk      AS sb_customer_sk,
            d.d_year               AS sb_year,
            r.r_reason_desc        AS sb_reason_desc,
            SUM(sr.sr_return_amt) AS sb_total_return_amt,
            COUNT(*)               AS sb_return_cnt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN reason r   ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE r.r_reason_desc LIKE '%Defect%'
          AND d.d_year = 2001
          AND cd.cd_gender = 'F'
          AND hd.hd_vehicle_count >= 2
          AND ca.ca_city = 'Seattle'
        GROUP BY sr.sr_returned_date_sk,
                 sr.sr_return_time_sk,
                 sr.sr_customer_sk,
                 d.d_year,
                 r.r_reason_desc
    ),
    catalog_base AS (
        SELECT
            cr.cr_returned_date_sk AS cb_returned_date_sk,
            cr.cr_returned_time_sk AS cb_returned_time_sk,
            cr.cr_refunded_customer_sk AS cb_customer_sk,
            d.d_year               AS cb_year,
            r.r_reason_desc        AS cb_reason_desc,
            SUM(cr.cr_return_amount) AS cb_total_return_amt,
            COUNT(*)               AS cb_return_cnt
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN reason r   ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        WHERE r.r_reason_desc = 'Customer not satisfied'
          AND d.d_year = 2001
          AND c.c_birth_country = 'United States'
        GROUP BY cr.cr_returned_date_sk,
                 cr.cr_returned_time_sk,
                 cr.cr_refunded_customer_sk,
                 d.d_year,
                 r.r_reason_desc
    ),
    full_joined AS (
        SELECT *
        FROM web_base wb
        FULL OUTER JOIN store_base sb
          ON wb.wb_sold_date_sk = sb.sb_returned_date_sk
         AND wb.wb_year = sb.sb_year
    ),
    intersect_customers AS (
        SELECT sr.sr_customer_sk AS cust_sk
        FROM store_returns sr
        INTERSECT
        SELECT cr.cr_refunded_customer_sk
        FROM catalog_returns cr
    )
SELECT
    fj.wb_year                         AS year,
    fj.wb_web_site_sk                  AS web_site_sk,
    fj.wb_web_name                     AS web_site_name,
    fj.wb_total_sales                  AS total_sales,
    fj.wb_total_profit                 AS total_profit,
    fj.wb_sales_cnt                    AS sales_cnt,
    COALESCE(fj.sb_total_return_amt, 0) AS total_store_return_amt,
    COALESCE(cb.cb_total_return_amt, 0) AS total_catalog_return_amt,
    (
        SELECT SUM(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = fj.wb_bill_customer_sk
    )                                 AS cust_total_sales,
    SUM(fj.wb_total_sales) OVER (PARTITION BY fj.wb_web_site_sk ORDER BY fj.wb_year) AS cum_sales_by_site
FROM full_joined fj
LEFT JOIN catalog_base cb
  ON fj.wb_sold_date_sk = cb.cb_returned_date_sk
 AND fj.wb_year = cb.cb_year
WHERE fj.wb_bill_customer_sk IN (SELECT cust_sk FROM intersect_customers)
  AND fj.wb_total_sales > 1000
  AND fj.wb_total_profit > 0
  AND fj.wb_year BETWEEN 2000 AND 2002
  AND fj.wb_web_name IS NOT NULL
ORDER BY fj.wb_year DESC, fj.wb_total_sales DESC
LIMIT 100
