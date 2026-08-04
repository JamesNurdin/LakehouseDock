WITH promo_avg_discount AS (
    SELECT p.p_promo_sk,
           AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk
)
SELECT
    cs.cs_order_number,
    cp.cp_department,
    i.i_category,
    i.i_item_id,
    d.d_year,
    t.t_hour,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    p.p_promo_name,
    cs.cs_net_paid,
    ws.web_site_id,
    ws.web_country,
    wr.wr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_paid DESC) AS dept_row_num,
    CASE
        WHEN cs.cs_ext_discount_amt > (
            SELECT pad.avg_discount
            FROM promo_avg_discount pad
            WHERE pad.p_promo_sk = cs.cs_promo_sk
        ) THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_flag
FROM catalog_sales cs
JOIN date_dim d                 ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t                 ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i                     ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p                ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_returns wr            ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r                   ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_site ws                ON ws.web_open_date_sk = d.d_date_sk
WHERE cp.cp_type = 'monthly'
  AND i.i_category = 'Sports'
  AND p.p_channel_event = 'N'
  AND cd.cd_gender = 'F'
  AND hd.hd_buy_potential = '5000-10000'
  AND d.d_year = 2001
  AND t.t_hour BETWEEN 9 AND 17
LIMIT 100
