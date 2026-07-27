WITH joined AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        cc.cc_name,
        cc.cc_gmt_offset,
        ws.web_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        r.r_reason_desc,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        cr.cr_return_amount,
        wr.wr_net_loss AS wr_net_loss,
        ws.ws_ext_sales_price
    FROM item i
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON c.c_customer_sk = sr.sr_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = sr.sr_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
    JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN web_site ws ON ws.web_site_sk = ws.ws_web_site_sk
    WHERE i.i_current_price BETWEEN 10 AND 500
      AND cc.cc_gmt_offset > -5.0
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk IN (1, 2, 3)
      AND r.r_reason_desc LIKE '%defect%'
)
SELECT
    j.i_item_id,
    j.i_product_name,
    j.cc_name AS call_center_name,
    j.web_name AS website_name,
    SUM(j.sr_net_loss) AS total_store_loss,
    SUM(j.cr_net_loss) AS total_catalog_loss,
    SUM(j.wr_net_loss) AS total_web_loss,
    SUM(j.sr_net_loss + j.cr_net_loss + j.wr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(j.cr_return_amount) > 1000 THEN 'High Return'
        ELSE 'Low Return'
    END AS return_category,
    (SELECT AVG(ws2.ws_ext_sales_price)
       FROM web_sales ws2
      WHERE ws2.ws_item_sk = j.i_item_sk) AS avg_sales_price,
    ROW_NUMBER() OVER (ORDER BY SUM(j.sr_net_loss + j.cr_net_loss + j.wr_net_loss) DESC) AS loss_rank
FROM joined j
GROUP BY
    j.i_item_id,
    j.i_product_name,
    j.cc_name,
    j.web_name,
    j.i_item_sk
ORDER BY loss_rank
LIMIT 100
