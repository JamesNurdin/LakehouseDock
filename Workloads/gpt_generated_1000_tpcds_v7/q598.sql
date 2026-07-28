WITH return_summary AS (
    SELECT
        cc.cc_call_center_id,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND i.i_brand = 'Brand#12'
      AND cc.cc_state = 'TX'
      AND wp.wp_autogen_flag = 'N'
      AND inv.inv_quantity_on_hand > 100
    GROUP BY cc.cc_call_center_id, d.d_year
)
SELECT
    cc_call_center_id,
    AVG(total_net_loss) AS avg_monthly_net_loss,
    SUM(total_return_amount) AS sum_return_amount,
    COUNT(*) AS months_reported
FROM return_summary
GROUP BY cc_call_center_id
HAVING AVG(total_net_loss) > 1000
ORDER BY avg_monthly_net_loss DESC
LIMIT 10
