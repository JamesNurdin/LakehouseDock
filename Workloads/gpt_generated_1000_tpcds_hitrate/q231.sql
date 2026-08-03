WITH sales_join AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_promo_sk,
        ss.ss_sold_time_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_category_id,
        i.i_rec_start_date,
        p.p_channel_press,
        t.t_hour,
        cd.cd_gender,
        cd.cd_education_status
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category_id IN (1, 3, 7)
      AND i.i_rec_start_date = DATE '1999-10-28'
      AND p.p_channel_press = 'N'
      AND t.t_hour BETWEEN 8 AND 12
      AND ss.ss_quantity > 2
      AND ss.ss_ext_sales_price > (
          SELECT MAX(ss2.ss_ext_sales_price)
          FROM store_sales ss2
          WHERE ss2.ss_sold_date_sk = 2450545
      )
),
returns_join AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        r.r_reason_desc,
        td.t_hour AS return_hour,
        cd2.cd_gender AS return_customer_gender
    FROM web_returns wr
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd2 ON wr.wr_refunded_cdemo_sk = cd2.cd_demo_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND td.t_hour BETWEEN 8 AND 12
),
union_data AS (
    SELECT
        sj.i_category_id AS category_id,
        sj.i_rec_start_date AS start_date,
        SUM(sj.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        AVG(sj.ss_ext_discount_amt) AS avg_discount,
        SUM(rj.wr_return_amt) AS total_returns,
        COUNT(rj.wr_return_quantity) AS returns_cnt
    FROM sales_join sj
    LEFT JOIN returns_join rj
        ON sj.ss_item_sk = rj.wr_item_sk
       AND sj.ss_sold_time_sk = rj.wr_returned_time_sk
    GROUP BY sj.i_category_id, sj.i_rec_start_date

    UNION

    SELECT
        sj.i_category_id,
        sj.i_rec_start_date,
        SUM(sj.ss_ext_sales_price) * 0.9 AS total_sales,
        COUNT(*) AS sales_cnt,
        AVG(sj.ss_ext_discount_amt) AS avg_discount,
        SUM(rj.wr_return_amt) AS total_returns,
        COUNT(rj.wr_return_quantity) AS returns_cnt
    FROM sales_join sj
    LEFT JOIN returns_join rj
        ON sj.ss_item_sk = rj.wr_item_sk
       AND sj.ss_sold_time_sk = rj.wr_returned_time_sk
    WHERE sj.p_channel_press = 'N'
    GROUP BY sj.i_category_id, sj.i_rec_start_date
)
SELECT
    category_id,
    start_date,
    SUM(total_sales) AS agg_total_sales,
    SUM(sales_cnt) AS agg_sales_cnt,
    AVG(avg_discount) AS agg_avg_discount,
    SUM(total_returns) AS agg_total_returns,
    SUM(returns_cnt) AS agg_returns_cnt
FROM union_data
GROUP BY category_id, start_date
ORDER BY agg_total_sales DESC
LIMIT 10
