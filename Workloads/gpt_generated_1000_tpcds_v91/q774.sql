WITH catalog_sales_agg AS ( 
    SELECT 
        cs.cs_catalog_page_sk,
        d.d_year AS sold_year,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_catalog_page_sk, d.d_year
),
store_sales_returns AS ( 
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_reason_sk
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_item_sk      = sr.sr_item_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    ca.sold_year,
    ca.total_sales_amount,
    ca.total_profit,
    ca.sales_cnt,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    s.s_store_name,
    ssr.ss_net_paid,
    ws.ws_net_paid,
    r.r_reason_desc,
    CASE 
        WHEN ca.total_profit > (SELECT AVG(cs_net_profit) FROM catalog_sales) THEN 'above_average'
        ELSE 'below_average'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY ca.sold_year ORDER BY ca.total_sales_amount DESC) AS sales_rank
FROM catalog_sales_agg ca
JOIN catalog_page cp
  ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_start
  ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON cp.cp_end_date_sk = d_end.d_date_sk
LEFT JOIN store_sales_returns ssr
  ON ssr.ss_sold_date_sk = d_start.d_date_sk
LEFT JOIN time_dim t_ss
  ON ssr.ss_sold_time_sk = t_ss.t_time_sk
LEFT JOIN customer c
  ON ssr.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd
  ON ssr.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
  ON ssr.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store s
  ON ssr.ss_store_sk = s.s_store_sk
LEFT JOIN reason r
  ON ssr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk     = ws.ws_item_sk
LEFT JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE cp.cp_department = 'Books'
  AND d_start.d_year BETWEEN 1999 AND 2001
  AND hd.hd_dep_count > 2
  AND r.r_reason_desc LIKE '%purchase%'
ORDER BY ca.sold_year DESC, ca.total_sales_amount DESC
LIMIT 100
