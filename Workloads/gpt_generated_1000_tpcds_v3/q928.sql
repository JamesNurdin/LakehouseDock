WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_return_ship_cost
    FROM store_returns sr
    WHERE sr.sr_return_amt > 50
      AND sr.sr_return_amt < 2000
      AND sr.sr_fee BETWEEN 5 AND 100
      AND sr.sr_return_quantity >= 1
      AND sr.sr_net_loss > 0
      AND sr.sr_return_ship_cost <= 50
),
joined AS (
    SELECT
        fr.sr_returned_date_sk,
        fr.sr_item_sk,
        fr.sr_return_amt,
        fr.sr_fee,
        fr.sr_return_quantity,
        fr.sr_net_loss,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        i.i_units,
        i.i_formulation
    FROM filtered_returns fr
    JOIN date_dim d ON fr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON fr.sr_item_sk = i.i_item_sk
    WHERE d.d_year IN (2000, 2001)
      AND d.d_day_name = 'Saturday'
      AND i.i_units = 'Dozen'
      AND i.i_current_price BETWEEN 5 AND 500
      AND i.i_formulation LIKE '%sky%'
      AND i.i_category = 'Sports'
),
aggregated AS (
    SELECT
        d_year,
        i_brand,
        i_category,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(sr_return_amt) >= 1000 THEN 'High'
            WHEN SUM(sr_return_amt) >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS return_amount_bucket
    FROM joined
    GROUP BY d_year, i_brand, i_category
),
ranked AS (
    SELECT
        d_year,
        i_brand,
        i_category,
        total_return_amt,
        total_net_loss,
        return_cnt,
        return_amount_bucket,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS return_amt_rownum
    FROM aggregated
)
SELECT DISTINCT
    r.d_year,
    r.i_brand,
    r.i_category,
    r.total_return_amt,
    r.total_net_loss,
    r.return_cnt,
    r.return_amount_bucket,
    r.net_loss_rank,
    r.return_amt_rownum
FROM ranked r
WHERE r.net_loss_rank <= 5
ORDER BY r.d_year ASC, r.net_loss_rank ASC
LIMIT 100
