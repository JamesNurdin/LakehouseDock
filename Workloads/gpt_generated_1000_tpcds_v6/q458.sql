WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND d.d_quarter_seq IN (2, 3)
      AND d.d_holiday = 'N'
      AND i.i_color = 'red'
      AND i.i_manufact = 'barcallyese'
      AND wr.wr_return_tax > 20
      AND wr.wr_return_amt_inc_tax > 100
),
agg_returns AS (
    SELECT
        fr.wr_item_sk,
        fr.wr_refunded_hdemo_sk,
        d.d_date,
        SUM(fr.wr_return_amt_inc_tax) AS total_return_amt,
        SUM(fr.wr_return_quantity) AS total_quantity,
        COUNT(*) AS return_cnt
    FROM filtered_returns fr
    JOIN date_dim d ON fr.wr_returned_date_sk = d.d_date_sk
    GROUP BY fr.wr_item_sk, fr.wr_refunded_hdemo_sk, d.d_date
),
distinct_items AS (
    SELECT DISTINCT
        ar.wr_item_sk,
        ar.wr_refunded_hdemo_sk,
        ar.d_date,
        ar.total_return_amt,
        ar.total_quantity,
        ar.return_cnt
    FROM agg_returns ar
),
final AS (
    SELECT
        di.d_date,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        di.total_return_amt,
        di.total_quantity,
        di.return_cnt,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        RANK() OVER (PARTITION BY i.i_brand ORDER BY di.total_return_amt DESC) AS brand_return_rank
    FROM distinct_items di
    JOIN item i ON di.wr_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd ON di.wr_refunded_hdemo_sk = hd.hd_demo_sk
)
SELECT
    d_date,
    i_item_id,
    i_product_name,
    i_brand,
    total_return_amt,
    total_quantity,
    return_cnt,
    buy_potential,
    brand_return_rank
FROM final
ORDER BY i_brand, brand_return_rank, d_date
