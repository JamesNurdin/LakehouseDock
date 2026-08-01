WITH sales_agg AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_paid,
        COUNT(*) AS sales_cnt,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_discount_amt > 500
      AND ws.ws_quantity >= 2
      AND ws.ws_ext_list_price < 20000
    GROUP BY ws.ws_web_page_sk, ws.ws_bill_cdemo_sk, ws.ws_bill_hdemo_sk
)
SELECT DISTINCT
    wp.wp_url,
    wp.wp_rec_end_date,
    cd.cd_gender,
    cd.cd_education_status,
    hd.hd_buy_potential,
    sa.total_paid,
    sa.sales_cnt,
    sa.avg_discount,
    (SELECT AVG(ws2.ws_ext_discount_amt) FROM tpcds.web_sales ws2) AS overall_avg_discount,
    (SELECT MAX(ws3.ws_net_paid_inc_tax)
        FROM tpcds.web_sales ws3
        WHERE ws3.ws_web_page_sk = wp.wp_web_page_sk) AS max_page_paid
FROM sales_agg sa
JOIN tpcds.web_page wp
    ON sa.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.customer_demographics cd
    ON sa.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON sa.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
  AND hd.hd_buy_potential = '>10000'
  AND wp.wp_rec_end_date = DATE '2001-09-02'
  AND wp.wp_link_count > 10
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws4
        WHERE ws4.ws_web_page_sk = wp.wp_web_page_sk
          AND ws4.ws_ext_discount_amt > 1000
      )
ORDER BY sa.total_paid DESC
LIMIT 100
