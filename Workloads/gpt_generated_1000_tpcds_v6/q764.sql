WITH cs_agg AS (
    SELECT
        cs_bill_customer_sk,
        cs_call_center_sk,
        cs_promo_sk,
        cs_sold_time_sk,
        SUM(cs_net_paid) AS total_net_paid,
        AVG(cs_net_profit) AS avg_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cs_bill_customer_sk, cs_call_center_sk, cs_promo_sk, cs_sold_time_sk
),
sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_store_sk,
        sr_return_time_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY sr_customer_sk, sr_store_sk, sr_return_time_sk
),
wr_agg AS (
    SELECT
        wr_refunded_customer_sk AS customer_sk,
        wr_returned_time_sk,
        SUM(wr_net_loss) AS web_return_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY wr_refunded_customer_sk, wr_returned_time_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    cc.cc_name AS call_center_name,
    p.p_promo_name,
    t_cs.t_hour AS sale_hour,
    cs_agg.total_net_paid,
    cs_agg.avg_profit,
    cs_agg.order_cnt,
    sr_agg.total_net_loss,
    sr_agg.return_cnt,
    wr_agg.web_return_loss,
    wr_agg.web_return_cnt,
    CASE
        WHEN p.p_discount_active = 'Y' THEN cs_agg.total_net_paid * 0.9
        ELSE cs_agg.total_net_paid
    END AS adjusted_total_paid
FROM cs_agg
JOIN customer c
    ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN time_dim t_cs
    ON cs_agg.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN sr_agg
    ON sr_agg.sr_customer_sk = c.c_customer_sk
LEFT JOIN store s
    ON sr_agg.sr_store_sk = s.s_store_sk
LEFT JOIN time_dim t_sr
    ON sr_agg.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN wr_agg
    ON wr_agg.customer_sk = c.c_customer_sk
LEFT JOIN time_dim t_wr
    ON wr_agg.wr_returned_time_sk = t_wr.t_time_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE
    cc.cc_state = 'CA'
    AND s.s_state = 'CA'
    AND p.p_channel_tv = 'N'
    AND t_cs.t_hour BETWEEN 9 AND 17
    AND ca.ca_country = 'United States'
LIMIT 100
