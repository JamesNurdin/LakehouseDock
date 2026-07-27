WITH sr_agg AS (
    SELECT
        sr_item_sk,
        sr_returned_date_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_tax > 5.00               -- filter predicate 1
    GROUP BY sr_item_sk, sr_returned_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    d.d_year,
    cc.cc_name AS call_center_name,
    p.p_promo_name,
    cs.cs_quantity,
    cs.cs_net_paid,
    CASE WHEN cs.cs_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category,
    sr_agg.total_return_amt,
    sr_agg.return_cnt,
    (
        SELECT SUM(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
    ) AS total_item_net_paid,
    RANK() OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_profit DESC) AS category_rank
FROM catalog_sales cs
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN sr_agg
    ON sr_agg.sr_item_sk = i.i_item_sk
   AND sr_agg.sr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
WHERE d.d_year = 2001                                 -- filter predicate 2
  AND ib.ib_upper_bound > 50000                        -- filter predicate 3
  AND p.p_discount_active = 'Y'
  AND cs.cs_quantity > 2
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_start_date_sk = d.d_date_sk
      )
ORDER BY category_rank, cs.cs_net_paid DESC
LIMIT 100
