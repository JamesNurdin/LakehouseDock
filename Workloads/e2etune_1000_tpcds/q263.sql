WITH filtered_returns AS (
  SELECT
    wr.wr_item_sk,
    wr.wr_returning_cdemo_sk,
    wr.wr_refunded_cdemo_sk,
    wr.wr_net_loss,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_refunded_cash,
    wr.wr_return_tax,
    wr.wr_fee,
    wr.wr_returning_customer_sk,
    wr.wr_order_number
  FROM web_returns wr
  WHERE wr.wr_net_loss > 0
),
agg_returns AS (
  SELECT
    i.i_category,
    i.i_brand,
    cd_ret.cd_education_status AS returning_education,
    cd_ret.cd_gender AS returning_gender,
    cd_ref.cd_education_status AS refunded_education,
    cd_ref.cd_gender AS refunded_gender,
    COUNT(*) AS num_returns,
    SUM(fr.wr_net_loss) AS total_net_loss,
    AVG(fr.wr_return_quantity) AS avg_return_qty,
    SUM(fr.wr_return_amt) AS total_return_amount,
    SUM(fr.wr_refunded_cash) AS total_refunded_cash
  FROM filtered_returns fr
  JOIN item i ON fr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd_ret ON fr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN customer_demographics cd_ref ON fr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  WHERE i.i_current_price BETWEEN 20 AND 200
    AND cd_ret.cd_purchase_estimate >= 1500
    AND cd_ref.cd_credit_rating = 'Good'
  GROUP BY i.i_category, i.i_brand,
           cd_ret.cd_education_status, cd_ret.cd_gender,
           cd_ref.cd_education_status, cd_ref.cd_gender
  HAVING SUM(fr.wr_net_loss) > 0
)
SELECT
  a.*, 
  RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank
FROM agg_returns a
ORDER BY a.total_net_loss DESC
LIMIT 15
