WITH sales_data AS (
    SELECT
        cs.cs_item_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_brand,
        cc.cc_state,
        cp.cp_type,
        hd.hd_income_band_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_paid > 1000
      AND i.i_current_price > 50
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'P'
      AND hd.hd_income_band_sk BETWEEN 2 AND 5
),
returns_data AS (
    SELECT
        sr.sr_item_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_brand,
        hd.hd_income_band_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
      AND ca.ca_state <> 'TX'
      AND i.i_current_price < 200
),
sales_summary AS (
    SELECT
        sd.cs_item_sk,
        sd.i_item_id,
        SUM(sd.cs_quantity) AS total_quantity_sold,
        SUM(sd.cs_net_paid) AS total_net_paid,
        SUM(sd.cs_ext_sales_price) AS total_ext_sales_price,
        SUM(sd.cs_coupon_amt) AS total_coupon_amount,
        SUM(sd.cs_ext_discount_amt) AS total_discount_amount,
        SUM(sd.cs_net_profit) AS total_net_profit
    FROM sales_data sd
    GROUP BY sd.cs_item_sk, sd.i_item_id
),
returns_summary AS (
    SELECT
        rd.sr_item_sk,
        rd.i_item_id,
        SUM(rd.sr_return_quantity) AS total_quantity_returned,
        SUM(rd.sr_return_amt) AS total_return_amount,
        SUM(rd.sr_fee) AS total_fee,
        SUM(rd.sr_net_loss) AS total_net_loss
    FROM returns_data rd
    GROUP BY rd.sr_item_sk, rd.i_item_id
),
combined_summary AS (
    SELECT
        COALESCE(s.cs_item_sk, r.sr_item_sk) AS item_sk,
        COALESCE(s.i_item_id, r.i_item_id) AS i_item_id,
        COALESCE(s.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
        COALESCE(s.total_net_paid, 0) AS total_net_paid,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        COALESCE(r.total_net_loss, 0) AS total_net_loss
    FROM sales_summary s
    FULL OUTER JOIN returns_summary r
        ON s.cs_item_sk = r.sr_item_sk
)
SELECT
    cs.item_sk,
    cs.i_item_id,
    cs.total_quantity_sold,
    cs.total_quantity_returned,
    cs.total_net_paid,
    cs.total_return_amount,
    cs.total_net_profit,
    cs.total_net_loss,
    CASE
        WHEN (cs.total_net_profit - cs.total_net_loss) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    (
        SELECT COUNT(*)
        FROM combined_summary cs2
        WHERE cs2.total_net_profit > cs.total_net_profit
    ) AS higher_profit_item_count,
    SUM(cs.total_net_profit) OVER (
        PARTITION BY CASE WHEN cs.total_quantity_sold > 0 THEN 'Sold' ELSE 'ReturnedOnly' END
    ) AS profit_by_category,
    RANK() OVER (ORDER BY (cs.total_net_profit - cs.total_net_loss) DESC) AS profit_rank
FROM combined_summary cs
WHERE cs.total_net_paid > 2000
  AND cs.total_return_amount > 0
  AND cs.total_quantity_sold > 10
  AND cs.total_quantity_returned < 5
ORDER BY profit_rank
LIMIT 100
