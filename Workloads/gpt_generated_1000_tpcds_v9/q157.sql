WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_state,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS net_category
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 1998
        AND cs.cs_quantity > 5
        AND cc.cc_state = 'CA'
        AND p.p_discount_active = 'Y'
    GROUP BY ROLLUP (d.d_year, d.d_month_seq, cc.cc_state)
)
SELECT
    d_year,
    d_month_seq,
    cc_state,
    order_cnt,
    total_net_paid,
    total_return_net_loss,
    total_web_return_loss,
    net_category,
    total_net_paid / NULLIF(SUM(total_net_paid) OVER (PARTITION BY d_year), 0) AS pct_of_year_net,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rank_state_by_net,
    (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = sales_agg.d_year
          AND d2.d_month_seq = sales_agg.d_month_seq
    ) AS avg_monthly_net_paid
FROM sales_agg
ORDER BY d_year, d_month_seq, rank_state_by_net
LIMIT 100
