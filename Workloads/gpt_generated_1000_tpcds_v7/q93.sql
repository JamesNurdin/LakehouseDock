/*
  goal: Identify the top‑selling stores for a given year, ranking them by total net profit from catalog sales while applying several business filters. The query joins all 15 selected TPC‑DS tables using only the permitted join keys, includes a scalar subquery to show the average catalog‑sales profit for the same day, and uses a window function (RANK) to order stores by profit.
*/
WITH joined AS (
    SELECT
        d.d_date                AS d_date,
        d.d_date_sk             AS d_date_sk,
        d.d_year                AS d_year,
        s.s_store_name          AS s_store_name,
        cs.cs_net_profit        AS cs_net_profit,
        cs.cs_quantity          AS cs_quantity,
        cc.cc_city              AS cc_city,
        w.w_state               AS w_state,
        r.r_reason_desc         AS r_reason_desc,
        ca.ca_city              AS ca_city,
        hd.hd_income_band_sk    AS hd_income_band_sk,
        t.t_time_sk             AS t_time_sk
    FROM            date_dim      d
    INNER JOIN      catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN      catalog_page  cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN      call_center   cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN      warehouse     w  ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    INNER JOIN      customer      cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    INNER JOIN      customer_address ca   ON cs.cs_bill_addr_sk   = ca.ca_address_sk
    INNER JOIN      household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN      time_dim      t   ON cs.cs_sold_time_sk   = t.t_time_sk
    INNER JOIN      store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN      store         s   ON s.s_store_sk        = sr.sr_store_sk
    INNER JOIN      reason        r   ON r.r_reason_sk       = sr.sr_reason_sk
    INNER JOIN      catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN      web_sales     ws  ON ws.ws_sold_date_sk  = d.d_date_sk
    INNER JOIN      web_returns   wr  ON wr.wr_returned_date_sk = d.d_date_sk
    -- additional rule‑based constraints to satisfy the join definitions
    WHERE
        d.d_year = 2001
        AND cc.cc_city = 'Fairview'
        AND w.w_state IN ('AL', 'NY')
        AND r.r_reason_desc LIKE '%damaged%'
        AND ca.ca_city = 'Spring'
        AND hd.hd_income_band_sk BETWEEN 5 AND 10
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_customer_sk   = cust.c_customer_sk
        AND sr.sr_hdemo_sk      = hd.hd_demo_sk
        AND sr.sr_addr_sk       = ca.ca_address_sk
        AND s.s_closed_date_sk  = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_item_sk          = cs.cs_item_sk
        AND cr.cr_refunded_customer_sk = cust.c_customer_sk
        AND cr.cr_refunded_hdemo_sk    = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk     = ca.ca_address_sk
        AND cr.cr_returning_customer_sk = cust.c_customer_sk
        AND cr.cr_returning_hdemo_sk    = hd.hd_demo_sk
        AND cr.cr_returning_addr_sk     = ca.ca_address_sk
        AND cr.cr_call_center_sk        = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk       = cp.cp_catalog_page_sk
        AND cr.cr_warehouse_sk          = w.w_warehouse_sk
        AND cr.cr_reason_sk             = r.r_reason_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk          = ws.ws_item_sk
        AND wr.wr_refunded_customer_sk = cust.c_customer_sk
        AND wr.wr_refunded_hdemo_sk    = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk     = ca.ca_address_sk
        AND wr.wr_returning_customer_sk = cust.c_customer_sk
        AND wr.wr_returning_hdemo_sk    = hd.hd_demo_sk
        AND wr.wr_returning_addr_sk     = ca.ca_address_sk
        AND wr.wr_reason_sk             = r.r_reason_sk
)
SELECT
    d_date,
    s_store_name,
    SUM(cs_net_profit)                      AS total_net_profit,
    COUNT(*)                                 AS transaction_cnt,
    RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank,
    (SELECT AVG(cs2.cs_net_profit)
       FROM catalog_sales cs2
      WHERE cs2.cs_sold_date_sk = j.d_date_sk) AS avg_daily_profit
FROM joined j
GROUP BY d_date, s_store_name, j.d_date_sk
ORDER BY profit_rank, d_date
LIMIT 100
