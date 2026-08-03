WITH base_agg AS (
    SELECT
        i.i_item_id,
        s.s_store_name,
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(sr.sr_net_loss) AS total_store_returns,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(wr.wr_net_loss) AS total_web_returns,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_sales cs
      ON cs.cs_item_sk = i.i_item_sk
     AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
     AND cs.cs_ship_hdemo_sk = hd.hd_demo_sk
     AND cs.cs_bill_addr_sk = ca.ca_address_sk
     AND cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
     AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_state = 'CA'
        AND cc.cc_state = 'CA'
        AND i.i_brand = 'Brand#12'
        AND w.w_state = 'WA'
        AND cs.cs_ship_date_sk BETWEEN 2450000 AND 2455000
        AND hd.hd_dep_count > 2
        AND ss.ss_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_current_price > 100)
    GROUP BY CUBE (i.i_item_id, s.s_store_name, ca.ca_state)
),
expanded AS (
    SELECT
        ba.i_item_id,
        ba.s_store_name,
        ba.ca_state,
        t.sales_amount,
        d.discounted_sales
    FROM base_agg ba
    CROSS JOIN UNNEST(ARRAY[ba.total_store_sales, ba.total_catalog_sales]) AS t(sales_amount)
    CROSS JOIN LATERAL (
        SELECT t.sales_amount * 0.9 AS discounted_sales
    ) d
)
SELECT
    i_item_id,
    s_store_name,
    ca_state,
    SUM(discounted_sales) AS sum_discounted_sales,
    AVG(sales_amount) AS avg_sales_amount
FROM expanded
WHERE sales_amount > 0
GROUP BY CUBE (i_item_id, s_store_name, ca_state)
HAVING SUM(discounted_sales) > 500
ORDER BY i_item_id, s_store_name, ca_state
LIMIT 100
