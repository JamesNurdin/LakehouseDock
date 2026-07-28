WITH rr_agg AS (
   SELECT
       sr_item_sk,
       sr_reason_sk,
       COUNT(*) AS return_cnt,
       SUM(sr_return_amt) AS total_return_amt,
       SUM(sr_net_loss) AS total_net_loss
   FROM store_returns
   WHERE sr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2000
   )
   GROUP BY sr_item_sk, sr_reason_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    cd.cd_gender,
    cd.cd_credit_rating,
    d.d_month_seq,
    cc.cc_name,
    ws.web_name,
    wp.wp_type,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    SUM(CASE WHEN ss.ss_quantity > 5 THEN ss.ss_ext_sales_price ELSE 0 END) AS sales_qty_gt_5,
    COALESCE(rr_agg.return_cnt, 0) AS return_count,
    COALESCE(rr_agg.total_return_amt, 0) AS return_amount,
    COALESCE(rr_agg.total_net_loss, 0) AS total_return_loss,
    r.r_reason_desc,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High'
        WHEN SUM(ss.ss_ext_sales_price) BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_volume_category
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN rr_agg ON ss.ss_item_sk = rr_agg.sr_item_sk
LEFT JOIN reason r ON rr_agg.sr_reason_sk = r.r_reason_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_date_sk = d.d_date_sk
WHERE
    d.d_year = 2000
    AND cd.cd_gender = 'M'
    AND cd.cd_credit_rating = 'Good'
    AND i.i_brand = 'Brand#23'
    AND p.p_channel_radio = 'N'
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    cd.cd_gender,
    cd.cd_credit_rating,
    d.d_month_seq,
    cc.cc_name,
    ws.web_name,
    wp.wp_type,
    rr_agg.return_cnt,
    rr_agg.total_return_amt,
    rr_agg.total_net_loss,
    r.r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
