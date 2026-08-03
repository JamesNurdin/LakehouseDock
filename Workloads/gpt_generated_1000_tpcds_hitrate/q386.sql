WITH joined_data AS (
    SELECT
        i.i_category,
        cc.cc_division_name,
        t.t_sub_shift,
        SUM(cs.cs_net_paid) AS sum_cs_net_paid,
        SUM(ss.ss_net_paid) AS sum_ss_net_paid,
        SUM(ws.ws_net_paid) AS sum_ws_net_paid,
        SUM(COALESCE(cr.cr_return_amount, 0) + COALESCE(sr.sr_return_amt, 0) + COALESCE(wr.wr_return_amt, 0)) AS sum_total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS cnt_cs_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_ss_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS cnt_ws_orders,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category = i.i_category) AS avg_category_price,
        GROUPING(i.i_category) AS g_category,
        GROUPING(cc.cc_division_name) AS g_division,
        GROUPING(t.t_sub_shift) AS g_sub_shift
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = i.i_item_sk
     AND sr.sr_return_time_sk = t.t_time_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = i.i_item_sk
     AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_start_date <= DATE '2001-12-31'
      AND t.t_sub_shift = 'night'
      AND ca.ca_county = 'York County'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_item_sk = i.i_item_sk
            AND cr2.cr_return_amount > 100
      )
    GROUP BY ROLLUP (i.i_category, cc.cc_division_name, t.t_sub_shift)
    HAVING SUM(cs.cs_net_paid) > 1000
)
SELECT *
FROM joined_data
ORDER BY sum_cs_net_paid DESC
LIMIT 100
