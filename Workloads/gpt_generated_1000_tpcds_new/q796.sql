WITH recent_dates AS (
      SELECT d_date_sk
      FROM date_dim
      WHERE d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    ),
    store_return_data AS (
      SELECT
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        d.d_year,
        i.i_class,
        s.s_state,
        cc.cc_country,
        ws.web_state,
        CASE WHEN sr.sr_return_amt > 100 THEN 'high' ELSE 'low' END AS return_level,
        ROW_NUMBER() OVER (PARTITION BY sr.sr_store_sk ORDER BY sr.sr_return_amt DESC) AS rn
      FROM store_returns sr
      JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
      JOIN item i ON sr.sr_item_sk = i.i_item_sk
      JOIN store s ON sr.sr_store_sk = s.s_store_sk
      JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_item_sk = i.i_item_sk
      JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
      JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
      WHERE d.d_date_sk IN (SELECT d_date_sk FROM recent_dates)
        AND d.d_year = 2000
        AND i.i_class IN ('sports-apparel', 'costume')
        AND s.s_state = 'CA'
        AND cc.cc_country = 'United States'
        AND ws.web_state = 'CA'
        AND EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_quantity_on_hand > 0
            AND inv2.inv_date_sk = d.d_date_sk
        )
    ),
    union_data AS (
      SELECT sr_store_sk, sr_return_amt
      FROM store_return_data
      WHERE return_level = 'high'
      UNION
      SELECT sr_store_sk, sr_return_amt
      FROM store_return_data
      WHERE sr_return_quantity > 5
    ),
    final_set AS (
      SELECT
        ud.sr_store_sk,
        SUM(ud.sr_return_amt) AS total_return_amount,
        COUNT(*) AS cnt_returns,
        RANK() OVER (ORDER BY SUM(ud.sr_return_amt) DESC) AS ret_rank
      FROM union_data ud
      GROUP BY ud.sr_store_sk
    )
SELECT
  fs.sr_store_sk,
  fs.total_return_amount,
  fs.cnt_returns,
  fs.ret_rank
FROM final_set fs
WHERE fs.sr_store_sk NOT IN (
        SELECT s_store_sk FROM store WHERE s_state = 'NY'
        EXCEPT
        SELECT sr_store_sk FROM store_returns
      )
ORDER BY fs.ret_rank
LIMIT 100
