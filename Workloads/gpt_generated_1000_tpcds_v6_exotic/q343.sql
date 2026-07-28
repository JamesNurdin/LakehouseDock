WITH union_returns AS (
   SELECT c.c_customer_sk AS customer_sk,
          d.d_year AS year,
          i.i_category AS category,
          cr.cr_net_loss AS net_loss,
          sm.sm_type,
          w.w_state,
          r.r_reason_desc,
          cd.cd_education_status
   FROM catalog_returns cr
   JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i                   ON cr.cr_item_sk = i.i_item_sk
   JOIN customer c               ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
   JOIN customer_address ca      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN ship_mode sm            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w             ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN web_sales ws            ON ws.ws_item_sk = i.i_item_sk
                                  AND ws.ws_sold_date_sk = d.d_date_sk
                                  AND ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_page wp             ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site we             ON ws.ws_web_site_sk = we.web_site_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Sports'
     AND r.r_reason_desc = 'Damaged'
     AND sm.sm_type = 'AIR'
     AND cd.cd_education_status = 'Advanced Degree'
     AND w.w_state = 'CA'
   UNION ALL
   SELECT c.c_customer_sk,
          d.d_year,
          i.i_category,
          sr.sr_net_loss,
          NULL AS sm_type,
          NULL AS w_state,
          r.r_reason_desc,
          cd.cd_education_status
   FROM store_returns sr
   JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i                   ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
   JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer_address ca      ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Sports'
     AND r.r_reason_desc = 'Damaged'
     AND cd.cd_education_status = 'Advanced Degree'
),
aggregated AS (
   SELECT customer_sk,
          year,
          category,
          SUM(net_loss) AS total_net_loss,
          COUNT(*)    AS return_cnt
   FROM union_returns
   GROUP BY customer_sk, year, category
)
SELECT a.customer_sk,
       a.year,
       a.category,
       a.total_net_loss,
       a.return_cnt,
       RANK() OVER (PARTITION BY a.year ORDER BY a.total_net_loss DESC) AS loss_rank,
       CASE WHEN a.total_net_loss > 1000 THEN 'High' ELSE 'Medium' END AS loss_level,
       (SELECT MAX(b.total_net_loss) FROM aggregated b) AS max_total_loss_overall
FROM aggregated a
WHERE EXISTS (
        SELECT 1
        FROM web_sales ws3
        JOIN date_dim d3 ON ws3.ws_sold_date_sk = d3.d_date_sk
        WHERE ws3.ws_bill_customer_sk = a.customer_sk
          AND d3.d_year = a.year
          AND ws3.ws_net_profit > 100
     )
ORDER BY a.year, loss_rank
LIMIT 100
