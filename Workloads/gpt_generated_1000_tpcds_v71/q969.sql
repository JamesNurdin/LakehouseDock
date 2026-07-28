WITH joined_data AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        ws.ws_web_site_sk,
        wsit.web_site_id,
        d.d_year,
        cr.cr_net_loss,
        wr.wr_net_loss,
        hd.hd_income_band_sk,
        c.c_customer_sk
    FROM call_center cc
    JOIN catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE cc.cc_state = 'CA'
      AND wsit.web_state = 'CA'
      AND d.d_year = 2001
      AND cr.cr_net_loss > 0
      AND wr.wr_net_loss > 0
      AND hd.hd_income_band_sk BETWEEN 1 AND 5
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
            AND cr2.cr_net_loss > 5000
      )
)
SELECT
    cc_name,
    web_site_id,
    d_year,
    SUM(cr_net_loss) AS total_catalog_loss,
    SUM(wr_net_loss) AS total_web_loss,
    SUM(cr_net_loss + wr_net_loss) AS total_loss,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY SUM(cr_net_loss + wr_net_loss) DESC) AS loss_rank,
    CASE
        WHEN SUM(cr_net_loss + wr_net_loss) > (
            SELECT AVG(year_total)
            FROM (
                SELECT SUM(cr_net_loss + wr_net_loss) AS year_total
                FROM joined_data jd2
                WHERE jd2.d_year = joined_data.d_year
                GROUP BY jd2.cc_name, jd2.web_site_id
            ) t
        ) THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM joined_data
GROUP BY cc_name, web_site_id, d_year
HAVING SUM(cr_net_loss + wr_net_loss) > 1000
ORDER BY total_loss DESC
LIMIT 100
