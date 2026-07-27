WITH base AS (
    SELECT
        d.d_year               AS d_year,
        d.d_month_seq          AS d_month_seq,
        i.i_category           AS i_category,
        i.i_class              AS i_class,
        i.i_brand              AS i_brand,
        ws.ws_ext_sales_price  AS ws_sales,
        ws.ws_net_profit       AS ws_profit,
        ws.ws_bill_customer_sk AS ws_bill_customer_sk,
        ws.ws_sold_time_sk     AS ws_sold_time_sk,
        t.t_hour               AS t_hour,
        ca.ca_state            AS ca_state,
        p.p_discount_active    AS p_discount_active,
        hd.hd_vehicle_count    AS hd_vehicle_count,
        sr.sr_return_amt       AS sr_return_amt,
        r.r_reason_desc        AS r_reason_desc,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        cp.cp_catalog_page_id  AS cp_catalog_page_id,
        s.s_store_name         AS s_store_name,
        wr.wr_return_amt       AS wr_return_amt,
        wsite.web_name         AS web_name
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN catalog_page cp
      ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_order_number = ws.ws_order_number
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    SUM(ws_sales)                           AS total_sales,
    SUM(ws_profit)                          AS total_profit,
    COUNT(DISTINCT ws_bill_customer_sk)    AS distinct_customers,
    SUM(CASE WHEN p_discount_active = 'Y' THEN ws_sales ELSE 0 END) AS promo_sales,
    AVG(hd_vehicle_count)                  AS avg_vehicle_count,
    SUM(sr_return_amt)                     AS total_return_amount,
    COUNT(DISTINCT r_reason_desc)          AS distinct_return_reasons
FROM base
WHERE d_year = 2001
  AND t_hour BETWEEN 9 AND 17
  AND ca_state = 'CA'
GROUP BY d_year, d_month_seq, i_category, i_class, i_brand
ORDER BY total_sales DESC
LIMIT 100
