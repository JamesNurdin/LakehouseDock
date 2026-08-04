WITH
  -- Fact table joined to store dimension with RIGHT OUTER JOIN (keep all stores)
  store_fact AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      c.c_customer_sk,
      i.i_item_sk,
      i.i_units,
      sr.sr_return_quantity,
      sr.sr_net_loss
    FROM store_returns sr
    RIGHT OUTER JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'                     -- filter 1
      AND i.i_units = 'Each'                    -- filter 2
  ),

  -- Catalog returns with Warehouse dimension using FULL OUTER JOIN (keep unmatched both sides)
  catalog_warehouse AS (
    SELECT
      cr.cr_item_sk AS i_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      i.i_brand_id,
      w.w_warehouse_name,
      CASE WHEN cr.cr_return_amount > 200 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns cr
    FULL OUTER JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 100            -- filter 3
      AND i.i_brand_id = 2002002
  ),

  -- Web returns enriched with web page and customer information
  web_join AS (
    SELECT
      wr.wr_item_sk AS i_item_sk,
      wr.wr_returned_date_sk,
      wr.wr_return_amt,
      wr.wr_net_loss,
      i.i_category,
      wp.wp_link_count,
      c.c_customer_sk
    FROM web_returns wr
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
      ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_link_count > 10               -- filter 4
      AND wr.wr_reversed_charge < 200
  ),

  -- Distinct item keys from store and catalog returns
  store_items AS (
    SELECT DISTINCT sr.sr_item_sk AS i_item_sk
    FROM store_returns sr
  ),
  catalog_items AS (
    SELECT DISTINCT cr.cr_item_sk AS i_item_sk
    FROM catalog_returns cr
  ),

  -- Subtract catalog items from store items using EXCEPT
  store_only_items AS (
    SELECT i_item_sk FROM store_items
    EXCEPT
    SELECT i_item_sk FROM catalog_items
  ),

  -- Filter store_fact to keep only items that are not present in catalog returns
  filtered_store_fact AS (
    SELECT sf.*
    FROM store_fact sf
    JOIN store_only_items soi
      ON sf.i_item_sk = soi.i_item_sk
  )

SELECT
  fsf.s_store_name,
  fsf.s_state,
  fsf.c_customer_sk,
  fsf.i_item_sk,
  fsf.sr_return_quantity,
  fsf.sr_net_loss,
  cw.amount_category,
  cw.w_warehouse_name,
  wj.i_category,
  wj.wp_link_count,
  RANK() OVER (PARTITION BY fsf.s_store_name ORDER BY fsf.sr_net_loss DESC) AS loss_rank,
  ROW_NUMBER() OVER (ORDER BY cw.cr_net_loss DESC NULLS LAST) AS overall_loss_rank
FROM filtered_store_fact fsf
LEFT JOIN catalog_warehouse cw
  ON fsf.i_item_sk = cw.i_item_sk
LEFT JOIN web_join wj
  ON fsf.i_item_sk = wj.i_item_sk
WHERE cw.amount_category IS NOT NULL               -- ensure the CASE expression produced a value
  AND wj.wp_link_count IS NOT NULL
ORDER BY loss_rank, fsf.s_store_name
OFFSET 0 FETCH NEXT 100 ROWS ONLY
