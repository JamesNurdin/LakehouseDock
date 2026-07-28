WITH sales_joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_sold_date_sk,
        c.c_customer_sk,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_category,
        i.i_item_sk,
        d.d_year,
        sm.sm_type,
        cc.cc_name,
        ws.web_site_id,
        inv.inv_quantity_on_hand,
        st.s_store_name,
        wp.wp_web_page_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN store st ON st.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND cs.cs_net_profit > 0
      AND ca.ca_country = 'United States'
      AND c.c_birth_country = 'CAMBODIA'
      AND cs.cs_sales_price > 50
),
aggregated AS (
    SELECT
        cd_gender,
        cd_marital_status,
        i_category,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT c_customer_sk) AS uniq_customers,
        AVG(cs_net_profit) AS avg_profit,
        MIN(c_customer_sk) AS sample_cust_sk
    FROM sales_joined
    GROUP BY cd_gender, cd_marital_status, i_category
)
SELECT
    ag.cd_gender,
    ag.cd_marital_status,
    ag.i_category,
    ag.total_profit,
    ag.uniq_customers,
    ag.avg_profit,
    RANK() OVER (ORDER BY ag.total_profit DESC) AS profit_rank,
    SUM(ag.total_profit) OVER (PARTITION BY ag.cd_gender) AS gender_total_profit,
    (
        SELECT AVG(sub.total_profit)
        FROM (
            SELECT SUM(cs.cs_net_profit) AS total_profit
            FROM catalog_sales cs
            JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = 2001
            GROUP BY cs.cs_bill_customer_sk
        ) sub
    ) AS overall_avg_customer_profit
FROM aggregated ag
WHERE ag.total_profit > 1000
  AND ag.uniq_customers >= 5
  AND NOT EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_refunded_customer_sk = ag.sample_cust_sk
  )
ORDER BY ag.total_profit DESC
LIMIT 100
