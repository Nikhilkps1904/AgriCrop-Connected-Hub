import React, { useState } from 'react';
import Web3 from 'web3';
import './AddItems.css';

const imageOptions = [
  { label: "Wheat", url: "https://cdn.pixabay.com/photo/2011/01/14/21/18/wheat-4509_640.jpg" },
  { label: "Jowar", url: "https://cdn.pixabay.com/photo/2014/02/26/13/20/sorghum-275258_640.jpg" },
  { label: "Maize", url: "https://cdn.pixabay.com/photo/2015/10/12/16/44/corn-984635_640.jpg" },
  { label: "Cotton", url: "https://cdn.pixabay.com/photo/2019/11/24/17/08/cotton-4649804_640.jpg" },
  { label: "Bajra", url: "https://cdn.pixabay.com/photo/2020/06/21/10/11/bajra-5324228_640.jpg" },
  { label: "Paddy", url: "https://cdn.pixabay.com/photo/2020/04/09/06/04/rice-5019854_1280.jpg" },
  { label: "Areca", url: "https://cdn.pixabay.com/photo/2019/03/04/08/48/areca-nut-4033593_640.jpg" }
];

const AddItems = ({ web3, accounts, contract, back }) => {
  const [name, setName] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [customImageUrl, setCustomImageUrl] = useState('');
  const [useCustomUrl, setUseCustomUrl] = useState(false);
  const [minBid, setMinBid] = useState('');
  const [buyoutPrice, setBuyoutPrice] = useState('');
  const [biddingTime, setBiddingTime] = useState(''); 
  // const [description,setDescription]=useState('');
  const [quantity,setQuantity]=useState('');

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!web3) {
      alert('Web3 is not initialized. Ensure MetaMask is connected.');
      return;
    }

    const finalImageUrl = useCustomUrl ? customImageUrl : imageUrl;

    if (!finalImageUrl) {
      alert('Please provide an image URL.');
      return;
    }

    try {
      // Convert biddingTime to seconds (if entered in minutes)
      const biddingTimeInSeconds = 100 * 60;

      await contract.methods.addItem(
        name,
        finalImageUrl,
        Web3.utils.toWei(minBid, 'ether'), // Assuming minBid and buyoutPrice are in Ether
        Web3.utils.toWei(buyoutPrice, 'ether'),
        quantity,
        biddingTimeInSeconds
        
      ).send({ from: accounts[0] });

      alert('Item added successfully!');
      // Optionally reset state here
      setName('');
      setImageUrl('');
      setCustomImageUrl('');
      setUseCustomUrl(false);
      setMinBid('');
      setBuyoutPrice('');
      setBiddingTime('');
      setQuantity('');
    } catch (error) {
      alert('Failed to add item. Error: ' + error.message);
    }
    back();
  };

  return (
    <form onSubmit={handleSubmit}>
      <h2>Add Auction Item</h2>
      <label>
        Item Name:
        <input type="text" value={name} onChange={(e) => setName(e.target.value)} required />
      </label>
      <label>
        Image URL:
        {!useCustomUrl ? (
          <>
            <select value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} required>
              <option value="">Select an Image URL</option>
              {imageOptions.map((option, index) => (
                <option key={index} value={option.url}>{option.label}</option>
              ))}
            </select>
            <button type="button" onClick={() => setUseCustomUrl(true)}>Set Custom URL</button>
          </>
        ) : (
          <>
            <input type="text" value={customImageUrl} onChange={(e) => setCustomImageUrl(e.target.value)} required />
            <button type="button" onClick={() => setUseCustomUrl(false)}>Use Dropdown</button>
          </>
        )}
      </label>
      <label>
        Minimum Bid (ETH):
        <input type="number" value={minBid} onChange={(e) => setMinBid((e.target.value))} required />
      </label>
      <label>
        Buyout Price (ETH):
        <input type="number" value={buyoutPrice} onChange={(e) => setBuyoutPrice((e.target.value))} required />
      </label>
      
      <label>
        Add Quantity
        <input type="number" value={quantity} onChange={(e) => setQuantity(e.target.value)} required />
      </label>

      <button type="submit">Add Item</button>
    </form>
  );
};

export default AddItems;
