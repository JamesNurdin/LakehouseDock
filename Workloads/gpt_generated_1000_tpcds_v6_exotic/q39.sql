WITH agg_sales AS (
    SELECT
        c.c_customer_id,
        w.w_state,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        i.i_class_id IN (11, 14)
        AND i.i_size = 'medium'
        AND ib.ib_lower_bound >= 60000
        AND td.t_hour BETWEEN 9 AND 17
        AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr2
            WHERE wr2.wr_item_sk = i.i_item_sk
              AND wr2.wr_return_amt > 5000
        )
    GROUP BY
        c.c_customer_id,
        w.w_state,
        i.i_category
    HAVING
        SUM(cs.cs_ext_sales_price) > 10000
)
SELECT DISTINCT
    a.c_customer_id,
    a.w_state,
    a.i_category,
    a.total_sales,
    a.total_profit,
    a.order_cnt,
    RANK() OVER (PARTITION BY a.w_state ORDER BY a.total_sales DESC) AS state_sales_rank,
    SUM(a.total_sales) OVER (PARTITION BY a.w_state) AS state_total_sales
FROM agg_sales a
ORDER BY a.total_sales DESC
LIMIT 100
