WITH joined_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_income_band_sk,
        w.w_warehouse_sk,
        w.w_state,
        w.w_warehouse_name,
        r.r_reason_desc,
        (cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) AS total_loss,
        CASE WHEN (cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
       AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
      AND cr.cr_net_loss > 0
      AND r.r_reason_desc LIKE '%product%'
      AND w.w_country = 'United States'
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
),
agg_data AS (
    SELECT
        w_state,
        ca_city,
        loss_category,
        SUM(total_loss) AS sum_total_loss
    FROM joined_data
    GROUP BY ROLLUP (w_state, ca_city, loss_category)
    HAVING SUM(total_loss) > 0
)
SELECT
    w_state,
    ca_city,
    loss_category,
    sum_total_loss,
    ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY sum_total_loss DESC) AS loss_rank
FROM agg_data
ORDER BY w_state, ca_city, loss_category
LIMIT 100
